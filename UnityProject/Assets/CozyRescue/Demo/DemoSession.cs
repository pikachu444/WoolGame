using System;
namespace CozyRescue.Demo
{
    public enum BlockPhase { Board, InTransit, Working, Finished }
    public enum DemoEventKind { Departure, Arrival, Capture, Complete, Won, Rejected, Reset }
    public sealed class DemoBlock
    {
        public int Id { get; internal set; }
        public int ColorId { get; internal set; }
        public int Capacity { get; internal set; }
        public int Remaining { get; internal set; }
        public int Slot { get; internal set; }
        public BlockPhase Phase { get; internal set; }
        public float DepartTime { get; internal set; }
        public float ArrivalTime { get; internal set; }
    }
    public sealed class DemoUnit
    {
        public int Id { get; internal set; }
        public int ColorId { get; internal set; }
        public bool Consumed { get; internal set; }
        public float CaptureTime { get; internal set; }
        public int CapturedBySlot { get; internal set; }
    }
    public readonly struct DemoEvent
    {
        public readonly DemoEventKind Kind;
        public readonly int BlockId, UnitId, Slot, Revision;
        public readonly float Time;
        public DemoEvent(DemoEventKind kind, int blockId, int unitId, int slot, float time, int revision)
        { Kind = kind; BlockId = blockId; UnitId = unitId; Slot = slot; Time = time; Revision = revision; }
    }
    /// <summary>Original visual fixture, not the future production puzzle core.</summary>
    public sealed class DemoSession
    {
        public static readonly int[] Capacities = { 4, 4, 6, 10 };
        public readonly DemoBlock[] Blocks = new DemoBlock[4];
        public readonly DemoUnit[] Units = new DemoUnit[24];
        private readonly double[] nextEvent = new double[4];
        private readonly int[] slots = new int[4];
        private double clock;
        private bool advancing;
        private const double Travel = .38, FirstCapture = .15, Cadence = .48;
        private static readonly int[][] Cells = { new[] { 2, 3 }, new[] { 0, 2 }, new[] { 1, 1, 1, 2 }, new[] { 0, 0, 1, 0, 2, 0 } };
        private static readonly int[] Dx = { 0, 1, 0, -1 }, Dy = { 1, 0, -1, 0 };
        public float Time => (float)clock;
        public int Revision { get; private set; }
        public bool Paused { get; set; }
        public bool Won { get; private set; }
        public int ConsumedCount { get; private set; }
        public event Action<DemoEvent> Changed;
        public DemoSession()
        {
            for (int i = 0; i < Blocks.Length; i++) Blocks[i] = new DemoBlock();
            for (int i = 0; i < Units.Length; i++) Units[i] = new DemoUnit();
            Reset();
        }
        public void Reset()
        {
            Revision++; clock = 0; Paused = false; Won = false; ConsumedCount = 0;
            int unit = 0;
            for (int i = 0; i < 4; i++)
            {
                int capacity = i < 2 ? 4 : i == 2 ? 6 : 10;
                DemoBlock b = Blocks[i];
                b.Id = b.ColorId = i; b.Capacity = b.Remaining = capacity;
                b.Slot = -1; b.Phase = BlockPhase.Board; b.DepartTime = b.ArrivalTime = -1;
                slots[i] = -1; nextEvent[i] = double.PositiveInfinity;
                for (int j = 0; j < capacity; j++, unit++)
                {
                    DemoUnit u = Units[unit]; u.Id = unit; u.ColorId = i;
                    u.Consumed = false; u.CaptureTime = -1; u.CapturedBySlot = -1;
                }
            }
            Emit(DemoEventKind.Reset, -1, -1, -1);
        }
        public bool CanSelect(int blockId)
        {
            if (Paused || Won || blockId < 0 || blockId >= 4 || Blocks[blockId].Phase != BlockPhase.Board) return false;
            bool free = false;
            for (int s = 0; s < 4; s++) if (slots[s] == -1) free = true;
            if (!free) return false;
            int[] cells = Cells[blockId];
            for (int step = 1; step <= 6; step++)
                for (int c = 0; c < cells.Length; c += 2)
                {
                    int x = cells[c] + Dx[blockId] * step, y = cells[c + 1] + Dy[blockId] * step;
                    if (x < 0 || x >= 6 || y < 0 || y >= 6) continue;
                    for (int other = 0; other < 4; other++)
                    {
                        if (other == blockId || Blocks[other].Phase != BlockPhase.Board) continue;
                        int[] occupied = Cells[other];
                        for (int o = 0; o < occupied.Length; o += 2)
                            if (occupied[o] == x && occupied[o + 1] == y) return false;
                    }
                }
            return true;
        }
        public bool TrySelect(int blockId)
        {
            if (!CanSelect(blockId)) { Emit(DemoEventKind.Rejected, blockId, -1, -1); return false; }
            int slot = 0;
            while (slots[slot] != -1) slot++;
            DemoBlock b = Blocks[blockId];
            slots[slot] = blockId; b.Slot = slot; b.Phase = BlockPhase.InTransit;
            b.DepartTime = Time; b.ArrivalTime = (float)(clock + Travel); nextEvent[blockId] = clock + Travel;
            Emit(DemoEventKind.Departure, blockId, -1, slot);
            return true;
        }
        public void Advance(float deltaSeconds)
        {
            if (Paused || advancing || deltaSeconds <= 0 || float.IsNaN(deltaSeconds) || float.IsInfinity(deltaSeconds)) return;
            double target = clock + deltaSeconds;
            int revision = Revision;
            advancing = true;
            try
            {
                while (true)
                {
                    int id = -1; double when = double.PositiveInfinity;
                    for (int i = 0; i < 4; i++) if (nextEvent[i] < when) { when = nextEvent[i]; id = i; }
                    if (id < 0 || when > target + .0000001) break;
                    clock = when;
                    DemoBlock b = Blocks[id];
                    if (b.Phase == BlockPhase.InTransit)
                    {
                        b.Phase = BlockPhase.Working; nextEvent[id] = when + FirstCapture;
                        Emit(DemoEventKind.Arrival, id, -1, b.Slot);
                    }
                    else
                    {
                        int unitId = -1;
                        for (int u = 0; u < Units.Length; u++)
                            if (!Units[u].Consumed && Units[u].ColorId == b.ColorId) { unitId = u; break; }
                        if (unitId < 0) throw new InvalidOperationException("Demo color supply exhausted before capacity.");
                        DemoUnit unit = Units[unitId];
                        unit.Consumed = true; unit.CaptureTime = Time; unit.CapturedBySlot = b.Slot;
                        b.Remaining--; ConsumedCount++;
                        bool complete = b.Remaining == 0;
                        nextEvent[id] = complete ? double.PositiveInfinity : when + Cadence;
                        int slot = b.Slot;
                        if (complete) { b.Phase = BlockPhase.Finished; slots[slot] = -1; }
                        Won = ConsumedCount == Units.Length;
                        Emit(DemoEventKind.Capture, id, unitId, slot);
                        if (Revision != revision) return;
                        if (complete) Emit(DemoEventKind.Complete, id, -1, slot);
                        if (Revision != revision) return;
                        if (Won) Emit(DemoEventKind.Won, -1, -1, -1);
                    }
                    if (Revision != revision || Paused) return;
                }
                // Success effects share this clock and must keep playing after logical completion.
                clock = Math.Max(clock, target);
            }
            finally { advancing = false; }
        }
        private void Emit(DemoEventKind kind, int blockId, int unitId, int slot)
        { Changed?.Invoke(new DemoEvent(kind, blockId, unitId, slot, Time, Revision)); }
    }
}
