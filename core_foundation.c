/* Ruby handles Ctrl+C at a safe point, which the run loop never reaches, so the system's default takes over. */
#include <CoreFoundation/CoreFoundation.h>
#include <signal.h>

void run_until_interrupted(void) {
  signal(SIGINT, SIG_DFL);
  CFRunLoopRun();
}
