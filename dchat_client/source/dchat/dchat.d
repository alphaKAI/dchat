module dchat.dchat;
import dchat.sockets,
       dchat.item,
       dchat.ui;
import std.string,
       std.regex,
       std.stdio,
       std.json,
       std.file,
       std.conv;
import core.thread;
import libasync;

class Dchat {
  private DchatUI ui;
  private core.thread.Thread uiThread;

  EventLoop     evl;
  TCPConnection conn;
  bool          flag;

  this() {
    write("please input your name : ");
    string name = readln.chomp;

    evl  = new EventLoop;
    conn = new TCPConnection(name, evl, "localhost", 8081);
    ui   = new DchatUI(conn);
    conn.setUI(ui);

    uiThread = new core.thread.Thread(&ui.guiMain);
    uiThread.start;

    while(!flag) {
      evl.loop();
    }

    destroyAsyncThreads();
  }
}