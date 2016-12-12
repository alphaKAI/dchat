import std.algorithm,
       std.array,
       std.stdio,
       std.json;
import libasync;

EventLoop   g_evl;
TCPListener g_listener;
bool        g_exit;

class TCPListener {
  AsyncTCPListener m_listener;

  this(string host, size_t port) {
    m_listener = new AsyncTCPListener(g_evl);

    if (m_listener.host(host, port).run(&handler)) {
      writeln("Listening to ", m_listener.local.toString());
    }
  }

  void delegate(TCPEvent) handler(AsyncTCPConnection conn) {
    auto tcpConn = new TCPConnection(conn);

    return &tcpConn.handler;
  }
}

class Distributor {
  AsyncTCPConnection[] clients;

  void addConn(AsyncTCPConnection conn) {
    this.clients ~= conn;
  }

  void deleteConn(AsyncTCPConnection conn) {
    this.clients = this.clients.filter!(_conn => conn != _conn).array;
  }

  void distribute(string msg, AsyncTCPConnection conn) {
    foreach (t_conn; clients) {
      t_conn.send(cast(ubyte[])msg);
    }
  }
}

static Distributor distr;

class TCPConnection {
  AsyncTCPConnection m_conn;
  string              name; // name of the client, it need not be an unique value

  this(AsyncTCPConnection conn) {
    this.m_conn = conn;

    if (distr is null) {
      distr = new Distributor;
    }

    distr.addConn(conn);
  }

  void onConnect() {
    // recieve the name of the client from the client
    writeln("onConnect!");
    ubyte[] bin = new ubyte[4092];
    uint len     = m_conn.recv(bin);
    string buf   = cast(string)bin[0..len];
    
    this.name = parseJSON(buf).object["name"].str;
    writeln("Recived a name of the new client : ", this.name);
  }

  void onRead() {
    static ubyte[] bin = new ubyte[4092];

    while (true) {
      uint len = m_conn.recv(bin);

      if (len > 0) {
        auto res = cast(string)bin[0..len];

        writefln("Received message from %s: %s ", this.name, res);

        distr.distribute(res, this.m_conn);
      }

      if (len < bin.length) {
        break;
      }
    }
  }

  void onWrite() {
    writeln("onWrite for " ~ this.name);
  }

  void onClose() {
    writeln("Connection closed");

    distr.deleteConn(this.m_conn);
  }

  void handler(TCPEvent ev) {
    final switch (ev) with (TCPEvent) {
      case CONNECT:
        onConnect();
        break;
      case READ:
        onRead();
        break;
      case WRITE:
        onWrite();
        break;
      case CLOSE:
        onClose();
        break;
      case ERROR:
        assert(false, "Error during TCP Event");
    }
    return;
  }
}

void main() {
  g_evl      = new EventLoop;
  g_listener = new TCPListener("localhost", 8081);

  while(!g_exit) {
    g_evl.loop();
  }

  destroyAsyncThreads();
}