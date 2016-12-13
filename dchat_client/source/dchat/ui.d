module dchat.ui;
import gtk.CellRendererPixbuf,
       gtk.CellRendererText,
       gtkc.gdkpixbuftypes,
       gtk.ScrolledWindow,
       gtk.TreeViewColumn,       
       gtk.MainWindow,
//       gtk.ObjectGtk,
       gtk.TextBuffer,
       gtk.TreeStore,
       gtk.ListStore,
       gtk.TextView,
       gtk.TreeIter,
       gtk.TreePath,
       gtk.TreeView,
       gtk.Button,
       gtk.Widget,
       gdk.Pixbuf,
       gtk.Label,
       gtk.Entry,
       gtk.Main,
       gtk.VBox,
       gtk.HBox;
import dchat.sockets,
       dchat.item;

class DchatUI {
  private {
    TreeStore      store;
    TreeView       view;
    ScrolledWindow swindow;
    string[]       opt;
    TCPConnection  conn;
  }

  this (TCPConnection conn) {
    this.conn = conn;
  }

  private void quit() {
    Main.quit;
    version(Posix){
      import core.thread,
             std.c.linux.linux;
      kill(getpid, SIGKILL);
    }
    // NEED : Add Windows
    //Need to more considering
  }

  private void post(string str) {
    this.conn.send(str);
  }

  public void guiMain(){
    Main.init(opt);
    MainWindow mainWindow = new MainWindow("DChat");
    VBox vbox = new VBox(false, 1);

    swindow = new ScrolledWindow;

    mainWindow.addOnDestroy(((Widget w) => quit));
    mainWindow.setDefaultSize(800, 800);

    store = new TreeStore([GType.STRING, GType.STRING]);
    view = new TreeView(store);

    TreeViewColumn idColumn  = new TreeViewColumn("1", new CellRendererText,   "text",   0);
    TreeViewColumn snColumn  = new TreeViewColumn("2", new CellRendererText,   "text",   1);

    idColumn.setMaxWidth(100);
    snColumn.setMaxWidth(300);

    view.appendColumn(idColumn);
    view.appendColumn(snColumn);

    swindow.addWithViewport(view);
    swindow.setMinContentHeight(500);
    swindow.setMinContentWidth(800);
    vbox.add(swindow);

    HBox hbox = new HBox(false, 2);
    TextView tv = new TextView;
    hbox.add(tv);
    Button postBtn = new Button("post", (Button) {
          string str = tv.getBuffer.getText;
          this.post(str);
          tv.setBuffer(null);
        });
    hbox.add(postBtn);
    vbox.add(hbox);

    mainWindow.add(vbox);

    mainWindow.showAll;
    Main.run;
  }

  public void addItem(Item item) {
    TreeIter root = store.prepend(null);

    store.setValue(root, 0, item.name);
    store.setValue(root, 1, item.text);
  }
}
