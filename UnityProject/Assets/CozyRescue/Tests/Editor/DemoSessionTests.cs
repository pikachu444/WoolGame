using System.Collections.Generic;
using CozyRescue.Demo;
using NUnit.Framework;

public sealed class DemoSessionTests
{
    [Test]
    public void BlockedFootprintsAndInvalidIdsLeaveStateUntouched()
    {
        var s = new DemoSession();
        var events = new List<DemoEvent>(); s.Changed += events.Add;
        Assert.IsTrue(s.CanSelect(0)); Assert.IsTrue(s.CanSelect(3));
        foreach (int id in new[] { 1, 2, -1, 4 }) Assert.IsFalse(s.TrySelect(id));
        Assert.AreEqual(4, events.Count);
        foreach (var e in events) Assert.AreEqual(DemoEventKind.Rejected, e.Kind);
        foreach (var b in s.Blocks) { Assert.AreEqual(BlockPhase.Board, b.Phase); Assert.AreEqual(-1, b.Slot); }
        Assert.AreEqual(0, s.Time); Assert.AreEqual(0, s.ConsumedCount);
        // C's full vertical sweep intersects the middle of D's wide footprint.
        Assert.IsTrue(s.TrySelect(3)); Assert.IsTrue(s.CanSelect(2));
        Assert.IsFalse(s.CanSelect(1)); Assert.IsTrue(s.TrySelect(2)); Assert.IsTrue(s.CanSelect(1));
    }
    [Test]
    public void ValidSequenceReservesFourUniqueSlotsAndRejectsRepeatedTap()
    {
        var s = new DemoSession();
        for (int id = 3; id >= 0; id--)
        {
            Assert.IsTrue(s.TrySelect(id)); Assert.IsFalse(s.TrySelect(id));
            Assert.AreEqual(3 - id, s.Blocks[id].Slot);
            Assert.AreEqual(BlockPhase.InTransit, s.Blocks[id].Phase);
        }
        s.Advance(.37f); Assert.AreEqual(0, s.ConsumedCount); s.Advance(.01f);
        foreach (var b in s.Blocks) Assert.AreEqual(BlockPhase.Working, b.Phase);
        s.Advance(.15f); Assert.AreEqual(4, s.ConsumedCount);
    }
    [Test]
    public void EveryStepConservesColorSupplyAndCompletionFiresOnce()
    {
        var s = new DemoSession(); int wins = 0, completes = 0, captures = 0;
        s.Changed += e => { if (e.Kind == DemoEventKind.Won) wins++; if (e.Kind == DemoEventKind.Complete) completes++; if (e.Kind == DemoEventKind.Capture) captures++; };
        for (int i = 3; i >= 0; i--) s.TrySelect(i);
        for (int step = 0; step < 100; step++)
        {
            s.Advance(.07f); int total = 0;
            for (int color = 0; color < 4; color++)
            {
                int consumed = 0; bool unconsumedSeen = false;
                foreach (var u in s.Units)
                {
                    if (u.ColorId != color) continue;
                    if (!u.Consumed) unconsumedSeen = true;
                    else { Assert.IsFalse(unconsumedSeen, "Consume head-to-tail per color"); consumed++; Assert.AreEqual(s.Blocks[color].Slot, u.CapturedBySlot); }
                }
                Assert.AreEqual(s.Blocks[color].Capacity, consumed + s.Blocks[color].Remaining); total += consumed;
            }
            Assert.AreEqual(total, s.ConsumedCount);
        }
        Assert.IsTrue(s.Won); Assert.AreEqual(24, captures); Assert.AreEqual(4, completes); Assert.AreEqual(1, wins);
        float before = s.Time; s.Advance(2); Assert.AreEqual(before + 2, s.Time, .00001f);
        Assert.AreEqual(1, wins); Assert.AreEqual(24, captures);
    }
    [Test]
    public void CompletedSlotIsImmediatelyReusable()
    {
        var s = new DemoSession(); s.TrySelect(0); s.Advance(2);
        Assert.AreEqual(BlockPhase.Finished, s.Blocks[0].Phase);
        Assert.IsTrue(s.TrySelect(3)); Assert.AreEqual(0, s.Blocks[3].Slot);
    }
    [Test]
    public void PauseFreezesClockAndCaptureThenResumeContinues()
    {
        var s = new DemoSession(); s.TrySelect(3); s.Advance(.6f);
        float time = s.Time; int count = s.ConsumedCount;
        s.Paused = true; s.Advance(100);
        Assert.AreEqual(time, s.Time); Assert.AreEqual(count, s.ConsumedCount); Assert.IsFalse(s.TrySelect(0));
        s.Paused = false; s.Advance(.48f); Assert.AreEqual(count + 1, s.ConsumedCount);
    }
    [Test]
    public void ResetMidflightAndMidCaptureRemovesOldScheduledWork()
    {
        foreach (float duration in new[] { .2f, .7f })
        {
            var s = new DemoSession(); s.TrySelect(3); s.Advance(duration);
            int revision = s.Revision; s.Reset();
            Assert.AreEqual(revision + 1, s.Revision); Assert.AreEqual(0, s.Time);
            s.Advance(20); Assert.AreEqual(0, s.ConsumedCount); Assert.IsFalse(s.Won);
            foreach (var b in s.Blocks) Assert.AreEqual(BlockPhase.Board, b.Phase);
            foreach (var u in s.Units) { Assert.IsFalse(u.Consumed); Assert.AreEqual(-1, u.CapturedBySlot); }
            Assert.IsTrue(s.TrySelect(3)); Assert.AreEqual(0, s.Blocks[3].Slot);
        }
    }
    [Test]
    public void DeltaPartitionsProduceSameOrderedEventTimeline()
    {
        var large = new DemoSession(); var small = new DemoSession();
        var a = new List<DemoEvent>(); var b = new List<DemoEvent>(); large.Changed += a.Add; small.Changed += b.Add;
        for (int id = 3; id >= 0; id--) { large.TrySelect(id); small.TrySelect(id); }
        large.Advance(6); for (int step = 0; step < 600; step++) small.Advance(.01f);
        Assert.AreEqual(a.Count, b.Count);
        for (int i = 0; i < a.Count; i++)
        {
            Assert.AreEqual(a[i].Kind, b[i].Kind); Assert.AreEqual(a[i].BlockId, b[i].BlockId);
            Assert.AreEqual(a[i].UnitId, b[i].UnitId); Assert.AreEqual(a[i].Slot, b[i].Slot);
            Assert.AreEqual(a[i].Time, b[i].Time, .000001f);
        }
    }
    [Test]
    public void ResetFromEventCannotApplyStaleCompletionOrAdvanceOldClock()
    {
        var s = new DemoSession(); int captures = 0;
        s.Changed += e => { if (e.Kind == DemoEventKind.Capture) { captures++; s.Reset(); } };
        s.TrySelect(3); s.Advance(20);
        Assert.AreEqual(1, captures); Assert.AreEqual(0, s.Time); Assert.AreEqual(0, s.ConsumedCount);
    }
}
