package com.annuo.pictools.launchqa;
import android.app.Activity;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.View;
import android.view.ViewTreeObserver;
public final class LaunchProbe extends Activity {
  @Override public void onCreate(Bundle state) {
    super.onCreate(state);
    View content = new View(this);
    int background = getResources().getIdentifier("launch_background", getIntent().getBooleanExtra("legacy", false) ? "drawable" : "color", getPackageName());
    content.setBackgroundResource(background);
    setContentView(content);
    if (!getIntent().getBooleanExtra("legacy", false)) {
      // Test harness only: expose the OS startup window long enough to capture.
      final long ready = SystemClock.uptimeMillis() + 2000;
      content.getViewTreeObserver().addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
        @Override public boolean onPreDraw() {
          if (SystemClock.uptimeMillis() < ready) return false;
          content.getViewTreeObserver().removeOnPreDrawListener(this);
          return true;
        }
      });
    }
  }
}
