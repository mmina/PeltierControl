import java.util.*;

public class Logger {
  PrintWriter output;
  
  public Logger(String filename) {
    output = createWriter(filename);
  }
  
  public Logger() {
    StringBuilder filename = new StringBuilder("Log");
    filename.append(year());
    int m = month();
    if (m < 10)  filename.append(0);
    filename.append(m);
    int d = day();
    if (d < 10)  filename.append(0);
    filename.append(d);
    int h = hour();
    if (h < 10)  filename.append(0);
    if (h == 0)  filename.append(0);
    filename.append(h);
    int min = minute();
    if (min < 10)  filename.append(0);
    if (min == 0)  filename.append(0);
    filename.append(min);
    filename.append(".txt");
    output = createWriter(filename.toString());
    println("logfile = " + filename);
  }
  
  public void log(String str) {
    int h = hour();
    int m = minute();
    int s = second();
    output.println(h + ":" + m + ":" + s + ", " + str);
  }
  
  public void logMillis(String str) {
    Calendar cal = new GregorianCalendar();
    int yy = cal.get(Calendar.YEAR);
    int mm = cal.get(Calendar.MONTH) + 1;  // Calendar.MONTHでは1月は0
    int dd = cal.get(Calendar.DAY_OF_MONTH);
    int h = cal.get(Calendar.HOUR_OF_DAY);
    int m = cal.get(Calendar.MINUTE);
    int s = cal.get(Calendar.SECOND);
    int milli = cal.get(Calendar.MILLISECOND);
    output.println(yy + ":" + mm + ":" + dd + ":" + h + ":" + m + ":" + s + ":" + milli + ", " + str);
  }
  
  public void close() {
    output.flush();
    output.close();
    return;
  }
}
