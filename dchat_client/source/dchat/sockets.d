module dchat.sockets;
import dchat.item,
       dchat.ui;
import std.stdio,
       std.json;
import libasync;

class TCPConnection {
  AsyncTCPConnection m_conn;
  string name;
  DchatUI ui = null;

  this(string name, EventLoop evl,
       string host, size_t port) {
    this.name = name;

    m_conn = new AsyncTCPConnection(evl);

    if (!m_conn.host(host, port).run(&handler)) {
      writeln(m_conn.status);
    }
  }

  void setUI(DchatUI ui) {
    this.ui = ui;
  }

  void onConnect() {
    m_conn.send(cast(ubyte[])(`{"name" : "` ~ this.name ~ `"}`));
    onRead;
  }

  void onRead() {
    static ubyte[] bin = new ubyte[4092];

    while (true) {
      uint len = m_conn.recv(bin);

      if (len > 0) {
        string res = cast(string)bin[0..len];
        
        if (ui !is null) {
          writeln("Recieved : ", res);
          auto parsed = parseJSON(res);
          Item item   = Item(parsed.object["name"].str, parsed.object["text"].str);
          ui.addItem(item);
        }
      }

      if (len < bin.length) {
        break;
      }
    }
  }

  void send(string msg) {
    string buf = `{"name":"` ~ this.name~ `", "text": "` ~ msg ~ `"}`;
    this.m_conn.send(cast(ubyte[])buf);
  }

  void onWrite() {}

  void onClose() {
    writeln("Connection closed");
  }

  void handler(TCPEvent ev) {
    try final switch (ev) {
      case TCPEvent.CONNECT:
        onConnect();
        break;
      case TCPEvent.READ:
        onRead();
        break;
      case TCPEvent.WRITE:
        onWrite();
        break;
      case TCPEvent.CLOSE:
        onClose();
        break;
      case TCPEvent.ERROR:
        assert(false, m_conn.error());
    } catch (Exception e) {
      assert(false, e.toString());
    }
    return;
  }
}