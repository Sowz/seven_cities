AGSScriptModule    monkey_05_06 Allows for creation of named timers with options to control whether the timer is run during normal game execution (while repeatedly_execute is run) or run always (while repeatedly_execute_always is run), whether the timer is automatically removed upon expiration, and pausing the timers temporarily. Timer 2.01 y  // Main script for module 'Timer'

TimerType Timer;
export Timer;

bool TimerType::IsNameValid(String name) {
  return ((name != null) && (name != "") && (name.Contains("//TimerStart") == -1) && (name.Contains("//TimerEnd") == -1));
  }

bool TimerType::Exists(String timer) {
  if ((!this.IsNameValid(timer)) || (this.__names == null)) return false;
  return (this.__names.Contains(String.Format("//TimerStart//%s//TimerEnd//", timer)) != -1);
  }

protected void TimerType::Reset(String timer) { // removes the timer from __BUFFER but not __NAMES, resetting all related
  if (!this.Exists(timer)) return; // variables without actually removing the timer
  int s = this.__buffer.Contains(String.Format("//TimerStart:%s//", timer));
  String e_str = String.Format("//TimerEnd:%s//", timer);
  int e = this.__buffer.Contains(e_str) + e_str.Length;
  String tbuff = this.__buffer.Substring(0, s);
  tbuff = tbuff.Append(this.__buffer.Substring(e, this.__buffer.Length));
  this.__buffer = tbuff;
  }

void TimerType::Remove(String timer) {
  if (!this.Exists(timer)) return;
  this.Reset(timer);
  String str = String.Format("//TimerStart//%s//TimerEnd//", timer);
  int i = this.__names.Contains(str);
  String nbuff = this.__names.Substring(0, i);
  i += str.Length;
  nbuff = nbuff.Append(this.__names.Substring(i, this.__names.Length));
  this.__names = nbuff;
  this.Count--;
  }



void TimerType::Set(String timer, int loops, Timer_RunAlwaysType runalways, Timer_AutoRemoveType autoremove, bool paused) {
  if (!this.IsNameValid(timer)) return;
  if (loops < 0) loops = GetGameSpeed();
  if (!this.Exists(timer)) {
    this.Count++;
    if (this.__names == null) this.__names = "";
    this.__names = this.__names.Append(String.Format("//TimerStart//%s//TimerEnd//", timer));
    }
  else this.Reset(timer);
  if (this.__buffer == null) this.__buffer = "";
  this.__buffer = this.__buffer.Append(String.Format("//TimerStart:%s//Loops:%d;RunAlways:%d;AutoRemove:%d;Paused:%d;//TimerEnd:%s//", timer, loops, (runalways != false), (autoremove != false), (paused != false), timer));
  }

int TimerType::GetLoopsRemaining(String timer) {
  if (!this.Exists(timer)) return 0;
  String s_str = String.Format("//TimerStart:%s//", timer);
  int s = this.__buffer.Contains(s_str) + s_str.Length;
  String buffer = this.__buffer.Substring(s + 6, this.__buffer.Length);
  buffer = buffer.Truncate(buffer.Contains(";"));
  return buffer.AsInt;
  }

bool TimerType::IsRunAlways(String timer) {
  if (!this.Exists(timer)) return false;
  String s_str = String.Format("//TimerStart:%s//", timer);
  int s = this.__buffer.Contains(s_str) + s_str.Length;
  String buffer = this.__buffer.Substring(s, this.__buffer.Length);
  buffer = buffer.Substring(buffer.Contains("RunAlways:") + 10, buffer.Length);
  buffer = buffer.Truncate(buffer.Contains(";"));
  return (buffer.AsInt != false);
  }

Timer_RunAlwaysType TimerType::GetRunAlwaysType(String timer) {
  if (!this.IsRunAlways(timer)) return eTimer_NotRunAlways;
  return eTimer_RunAlways;
  }

bool TimerType::IsAutoRemoved(String timer) {
  if (!this.Exists(timer)) return false;
  String s_str = String.Format("//TimerStart:%s//", timer);
  int s = this.__buffer.Contains(s_str) + s_str.Length;
  String buffer = this.__buffer.Substring(s, this.__buffer.Length);
  buffer = buffer.Substring(buffer.Contains("AutoRemove:") + 11, buffer.Length);
  buffer = buffer.Truncate(buffer.Contains(";"));
  return (buffer.AsInt != false);
  }

Timer_AutoRemoveType TimerType::GetAutoRemoveType(String timer) {
  if (!this.IsAutoRemoved(timer)) return eTimer_NoAutoRemove;
  return eTimer_AutoRemove;
  }

bool TimerType::IsExpired(String timer) {
  if (!this.Exists(timer)) return false;
  if (!this.GetLoopsRemaining(timer)) {
    if (this.IsAutoRemoved(timer)) this.Remove(timer);
    return true;
    }
  return false;
  }

bool TimerType::IsPaused(String timer) {
  if (!this.Exists(timer)) return false;
  String s_str = String.Format("//TimerStart:%s//", timer);
  int s = this.__buffer.Contains(s_str) + s_str.Length;
  String buffer = this.__buffer.Substring(s, this.__buffer.Length);
  buffer = buffer.Substring(buffer.Contains("Paused:") + 7, buffer.Length);
  buffer = buffer.Truncate(buffer.Contains(";"));
  return (buffer.AsInt != false);
  }

String TimerType::GetNameByID(int ID) {
  if ((ID < 0) || (ID >= this.Count) || (this.__names == null)) return "";
  int i = 0;
  String buffer = this.__names;
  String tstart = "//TimerStart//";
  String tend = "//TimerEnd//";
  while (i < ID) {
    int j = buffer.Contains(tend);
    if ((j == -1) || ((j + tend.Length) == buffer.Length)) return "";
    buffer = buffer.Substring(buffer.Contains(tstart) + tstart.Length, buffer.Length);
    buffer = buffer.Substring(j + tend.Length, buffer.Length);
    i++;
    }
  if (buffer.Contains(tstart) != -1) buffer = buffer.Substring(tstart.Length, buffer.Length);
  if (buffer.Contains(tend) != -1) buffer = buffer.Substring(0, buffer.Contains(tend));
  return buffer;
  }

void TimerType::Pause(String timer) {
  if ((!this.Exists(timer)) || (this.IsPaused(timer))) return;
  this.Set(timer, this.GetLoopsRemaining(timer), this.IsRunAlways(timer), this.IsAutoRemoved(timer), true);
  }

void TimerType::UnPause(String timer) {
  if ((!this.Exists(timer)) || (!this.IsPaused(timer))) return;
  this.Set(timer, this.GetLoopsRemaining(timer), this.IsRunAlways(timer), this.IsAutoRemoved(timer), false);
  }

function repeatedly_execute() {
  int i = 0;
  while (i < Timer.Count) {
    String j = Timer.GetNameByID(i);
    int loops = Timer.GetLoopsRemaining(j);
    if (loops > 0) loops--;
    if ((!Timer.IsPaused(j)) && (!Timer.IsRunAlways(j))) Timer.Set(j, loops, false, Timer.IsAutoRemoved(j), Timer.IsPaused(j));
    i++;
    }
  }

function repeatedly_execute_always() {
  int i = 0;
  while (i < Timer.Count) {
    String j = Timer.GetNameByID(i);
    int loops = Timer.GetLoopsRemaining(j);
    if (loops > 0) loops--;
    if ((!Timer.IsPaused(j)) && (Timer.IsRunAlways(j))) Timer.Set(j, loops, true, Timer.IsAutoRemoved(j), Timer.IsPaused(j));
    i++;
    }
  }
 �  // Script header for module 'Timer'

enum Timer_AutoRemoveType {
  eTimer_AutoRemove = 1,
  eTimer_NoAutoRemove = 0
  };

enum Timer_RunAlwaysType {
  eTimer_NotRunAlways = 0,
  eTimer_RunAlways = 1
  };

struct TimerType {
  protected String __buffer;
  protected String __names;
  writeprotected int Count;
  import bool Exists(String timer);
  import Timer_AutoRemoveType GetAutoRemoveType(String timer);
  import int GetLoopsRemaining(String timer);
  import String GetNameByID(int ID);
  import Timer_RunAlwaysType GetRunAlwaysType(String timer);
  import bool IsAutoRemoved(String timer);
  import bool IsExpired(String time);
  import bool IsNameValid(String name);
  import bool IsPaused(String timer);
  import bool IsRunAlways(String timer);
  import void Pause(String timer);
  import void Remove(String timer);
  protected import void Reset(String timer);
  import void Set(String timer, int loops, Timer_RunAlwaysType runalways=eTimer_RunAlways, Timer_AutoRemoveType autoremove=eTimer_AutoRemove, bool paused=false);
  import void UnPause(String timer);
  };

import TimerType Timer;

#define TIMER_VERSION 201  
#define TIMER_VERSION_201  
#define TIMER_VERSION_200  
#define TIMER_VERSION_100  
 D�        ej��