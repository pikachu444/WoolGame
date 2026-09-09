using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace CozyRescue.Presentation
{
    /// <summary>Opt-in local evidence recording; recording overhead is never a performance benchmark.</summary>
    public sealed class WoolEvidenceCapture : MonoBehaviour
    {
        public string outputDirectory;
        const int MaxInFlight = 3;
        sealed class Frame
        {
            public int index, width, height, consumed;
            public double wall;
            public float session;
            public bool full, detail, unravel, rescue;
            public string FileName => "frame_" + index.ToString("D5") + ".png";
        }
        sealed class Slot
        {
            public RenderTexture target;
            public bool reading;
            public Task<Frame> writer;
            public bool Free => !reading && writer == null;
        }
        readonly Slot[] slots = {new Slot(), new Slot(), new Slot()};
        readonly List<Frame> completed = new List<Frame>();
        readonly List<string> errors = new List<string>();
        bool useAsync, flipY;
        int dropped;

        IEnumerator Start()
        {
            if (string.IsNullOrEmpty(outputDirectory)) outputDirectory = Path.GetFullPath(Path.Combine(Application.dataPath, "../../Evidence"));
            string[] args = Environment.GetCommandLineArgs();
            for (int i = 0; i < args.Length - 1; i++) if (args[i] == "--wool-evidence-dir") outputDirectory = args[i + 1];
            Directory.CreateDirectory(outputDirectory);
            useAsync = SystemInfo.supportsAsyncGPUReadback && Array.IndexOf(args, "--wool-capture-async") >= 0 && Array.IndexOf(args, "--wool-capture-sync") < 0;
            flipY = Array.IndexOf(args, "--wool-capture-flip-y") >= 0;
            var lab = GetComponent<WoolLab>();
            var endOfFrame = new WaitForEndOfFrame();
            // Let fonts, canvas layout and camera settle, then reset the actual demo clock.
            yield return endOfFrame;
            yield return endOfFrame;
            lab.Replay();
            double begin = Time.realtimeSinceStartupAsDouble, next = 0;
            int frame = 0;
            bool full = false, detail = false, unravel = false, rescue = false;
            while (Time.realtimeSinceStartupAsDouble - begin < 16)
            {
                yield return endOfFrame;
                PollWriters();
                double wall = Time.realtimeSinceStartupAsDouble - begin;
                if (wall >= 16) break;
                if (wall < next) continue;
                // Wall-clock sampling: skipped frames remain gaps, never a synthetic speed-up.
                next += 1.0 / 30;
                if (next < wall) next = wall + 1.0 / 30;
                Slot free = null;
                foreach (var slot in slots) if (slot.Free) { free = slot; break; }
                if (free == null) { dropped++; continue; }
                float lastCapture = 0;
                foreach (var unit in lab.Session.Units) lastCapture = Mathf.Max(lastCapture, unit.CaptureTime);
                var item = new Frame {
                    index = frame++, wall = wall, session = lab.Session.Time, consumed = lab.Session.ConsumedCount,
                    width = Screen.width, height = Screen.height,
                    full = !full && lab.Session.Time >= .8f,
                    detail = !detail && lab.Session.Time >= 1,
                    unravel = !unravel && lab.Session.ConsumedCount >= 7 && !lab.Session.Won,
                    rescue = !rescue && lab.Session.Won && lab.Session.Time >= lastCapture + 1
                };
                full |= item.full; detail |= item.detail; unravel |= item.unravel; rescue |= item.rescue;
                QueueFrame(free, item);
            }
            // All GPU callbacks and bounded background writes must finish before CSV or application exit.
            bool busy;
            do {
                PollWriters();
                busy = false;
                foreach (var slot in slots) busy |= !slot.Free;
                if (busy) yield return null;
            } while (busy);
            completed.Sort((a, b) => a.wall.CompareTo(b.wall));
            var csv = new StringBuilder("file,wall_seconds,session_seconds,consumed\n");
            foreach (var item in completed)
                csv.Append(item.FileName).Append(',').Append(item.wall.ToString("F6", CultureInfo.InvariantCulture)).Append(',')
                    .Append(item.session.ToString("F6", CultureInfo.InvariantCulture)).Append(',').Append(item.consumed).Append('\n');
            File.WriteAllText(Path.Combine(outputDirectory, "frame_times.csv"), csv.ToString());
            File.WriteAllText(Path.Combine(outputDirectory, "capture_context.txt"),
                "Actual runtime screen capture over 16 wall-clock seconds after two warm-up frames and replay.\n" +
                "GPU readback, memory copies, PNG encoding and disk writes add recording overhead. This is NOT a performance benchmark.\n" +
                "No interpolated frames or altered simulation speed. Use frame_times.csv for video timing.\n" +
                "Default synchronous screen readback with background PNG writes (verified Windows captures). Experimental async requires --wool-capture-async; inspect orientation and use --wool-capture-flip-y when needed.\n" +
                "Unity=" + Application.unityVersion + "\nPlatform=" + Application.platform + "\nDevice=" + SystemInfo.deviceModel +
                "\nGPU=" + SystemInfo.graphicsDeviceName + "\nResolution=" + Screen.width + "x" + Screen.height +
                "\nAsyncGPUReadback=" + useAsync + "\nFlipY=" + flipY + "\nMaxInFlight=" + MaxInFlight +
                "\nFrames=" + completed.Count + "\nSkippedWhileQueueFull=" + dropped + "\nErrors=" + errors.Count + "\n" + string.Join("\n", errors) + "\n");
            foreach (var slot in slots) if (slot.target) { slot.target.Release(); Destroy(slot.target); slot.target = null; }
            if (errors.Count == 0) Debug.Log("WOOL_EVIDENCE_COMPLETE " + outputDirectory);
            else Debug.LogError("WOOL_EVIDENCE_INCOMPLETE " + outputDirectory + " " + string.Join("; ", errors));
            if (Array.IndexOf(args, "--wool-quit") >= 0) Application.Quit(errors.Count == 0 ? 0 : 1);
        }

        void QueueFrame(Slot slot, Frame item)
        {
            if (useAsync)
            {
                if (!slot.target || slot.target.width != item.width || slot.target.height != item.height)
                {
                    if (slot.target) { slot.target.Release(); Destroy(slot.target); }
                    slot.target = new RenderTexture(item.width, item.height, 0, RenderTextureFormat.ARGB32) { name = "Evidence readback" };
                    slot.target.Create();
                }
                ScreenCapture.CaptureScreenshotIntoRenderTexture(slot.target);
                slot.reading = true;
                AsyncGPUReadback.Request(slot.target, 0, TextureFormat.RGBA32, request => {
                    slot.reading = false;
                    if (request.hasError) { errors.Add(item.FileName + ": GPU readback failed"); useAsync = false; return; }
                    // Copy during the callback: request-owned native memory expires after this frame.
                    byte[] pixels = request.GetData<byte>().ToArray();
                    slot.writer = Task.Run(() => WriteFrame(item, pixels, GraphicsFormat.R8G8B8A8_UNorm, 4));
                });
            }
            else
            {
                Texture2D screenshot = ScreenCapture.CaptureScreenshotAsTexture();
                if (!screenshot) { errors.Add(item.FileName + ": screenshot failed"); return; }
                byte[] pixels = screenshot.GetRawTextureData();
                GraphicsFormat format = screenshot.graphicsFormat;
                int stride = pixels.Length / (item.width * item.height);
                Destroy(screenshot);
                slot.writer = Task.Run(() => WriteFrame(item, pixels, format, stride));
            }
        }

        Frame WriteFrame(Frame item, byte[] pixels, GraphicsFormat format, int pixelBytes)
        {
            int rowBytes = item.width * pixelBytes;
            if (flipY)
            {
                var row = new byte[rowBytes];
                for (int y = 0; y < item.height / 2; y++)
                {
                    int top = y * rowBytes, bottom = (item.height - 1 - y) * rowBytes;
                    Buffer.BlockCopy(pixels, top, row, 0, rowBytes);
                    Buffer.BlockCopy(pixels, bottom, pixels, top, rowBytes);
                    Buffer.BlockCopy(row, 0, pixels, bottom, rowBytes);
                }
            }
            // Unity 6.3 documents EncodeArrayToPNG as thread-safe. No Texture/scene API runs here.
            // https://docs.unity3d.com/6000.3/Documentation/ScriptReference/ImageConversion.EncodeArrayToPNG.html
            byte[] png = ImageConversion.EncodeArrayToPNG(pixels, format, (uint)item.width, (uint)item.height, (uint)rowBytes);
            File.WriteAllBytes(Path.Combine(outputDirectory, item.FileName), png);
            if (item.full) File.WriteAllBytes(Path.Combine(outputDirectory, "01_full.png"), png);
            if (item.unravel) File.WriteAllBytes(Path.Combine(outputDirectory, "03_unravel.png"), png);
            if (item.rescue) File.WriteAllBytes(Path.Combine(outputDirectory, "04_rescue.png"), png);
            if (item.detail)
            {
                // After optional full-buffer FlipY above, rows use Unity bottom origin, matching GetPixels.
                int y = (int)Math.Round(item.height * .68), height = (int)Math.Round(item.height * .23);
                byte[] crop = new byte[rowBytes * height];
                Buffer.BlockCopy(pixels, y * rowBytes, crop, 0, crop.Length);
                File.WriteAllBytes(Path.Combine(outputDirectory, "02_knit_detail.png"),
                    ImageConversion.EncodeArrayToPNG(crop, format, (uint)item.width, (uint)height, (uint)rowBytes));
            }
            return item;
        }

        void PollWriters()
        {
            foreach (var slot in slots)
            {
                if (slot.writer == null || !slot.writer.IsCompleted) continue;
                if (slot.writer.IsFaulted) errors.Add(slot.writer.Exception.GetBaseException().Message);
                else if (slot.writer.IsCanceled) errors.Add("PNG writer canceled");
                else completed.Add(slot.writer.Result);
                slot.writer = null;
            }
        }
    }
}


