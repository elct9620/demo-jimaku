/* objc_msgSend takes each message's own C types; Ruby cannot pass a rectangle by value, so these build one. */
#include <CoreGraphics/CGGeometry.h>
#include <objc/message.h>

void msg_send_rect(id target, SEL selector, double x, double y, double width, double height) {
  ((void (*)(id, SEL, CGRect))objc_msgSend)(target, selector, CGRectMake(x, y, width, height));
}

/* initWithContentRect:styleMask:backing:defer: */
id msg_send_content_rect(id target, SEL selector, double x, double y, double width, double height,
                         unsigned long style, unsigned long backing, BOOL defer) {
  return ((id (*)(id, SEL, CGRect, unsigned long, unsigned long, BOOL))objc_msgSend)(
      target, selector, CGRectMake(x, y, width, height), style, backing, defer);
}
