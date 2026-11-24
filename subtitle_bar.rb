# frozen_string_literal: true

# Objective-C has one entry point, objc_msgSend, declared once per message shape.
module ObjC
  ffi_lib 'objc'
  ffi_cflags '-framework AppKit'

  ffi_func :objc_getClass, [:str], :ptr
  ffi_func :sel_registerName, [:str], :ptr
  # A rectangle travels by value, which objc.c builds.
  ffi_func :msg_send_rect, %i[ptr ptr double double double double], :void
  ffi_func :msg_send_content_rect, %i[ptr ptr double double double double long long bool], :ptr

  module Send
    ffi_func :objc_msgSend, %i[ptr ptr], :ptr
  end

  module SendId
    ffi_func :objc_msgSend, %i[ptr ptr ptr], :ptr
  end

  module SendCString
    ffi_func :objc_msgSend, %i[ptr ptr str], :ptr
  end

  module SendLong
    ffi_func :objc_msgSend, %i[ptr ptr long], :ptr
  end

  module SendDoubles
    ffi_func :objc_msgSend, %i[ptr ptr double double], :ptr
  end
end

module CoreGraphics
  ffi_func :CGMainDisplayID, [], :uint32
  ffi_func :CGDisplayPixelsWide, [:uint32], :size_t
end

# A borderless window along the bottom of the screen, built by sending Objective-C messages.
class SubtitleBar
  HEIGHT = 120.0
  FONT_SIZE = 44.0
  LINE_HEIGHT = 54.0
  SIDE_MARGIN = 40.0
  BORDERLESS = 0
  BUFFERED = 2
  ABOVE_NORMAL_WINDOWS = 25
  CENTERED = 1

  def initialize
    ObjC::Send.objc_msgSend(cls('NSApplication'), sel('sharedApplication'))
    width = CoreGraphics.CGDisplayPixelsWide(CoreGraphics.CGMainDisplayID).to_f
    window = new_window(width)
    @label = new_label(width)
    ObjC::SendId.objc_msgSend(ObjC::Send.objc_msgSend(window, sel('contentView')), sel('addSubview:'), @label)
    ObjC::Send.objc_msgSend(window, sel('orderFrontRegardless'))
  end

  def show(text)
    ObjC::SendId.objc_msgSend(@label, sel('setStringValue:'), nsstring(text))
  end

  private

  def new_window(width)
    window = ObjC.msg_send_content_rect(ObjC::Send.objc_msgSend(cls('NSWindow'), sel('alloc')),
                                        sel('initWithContentRect:styleMask:backing:defer:'),
                                        0.0, 0.0, width, HEIGHT, BORDERLESS, BUFFERED, false)
    ObjC::SendLong.objc_msgSend(window, sel('setOpaque:'), 0)
    ObjC::SendId.objc_msgSend(window, sel('setBackgroundColor:'), color(0.0, 0.7))
    ObjC::SendLong.objc_msgSend(window, sel('setLevel:'), ABOVE_NORMAL_WINDOWS)
    ObjC::SendLong.objc_msgSend(window, sel('setIgnoresMouseEvents:'), 1)
    window
  end

  def new_label(width) # rubocop:disable Metrics/AbcSize
    label = ObjC::SendId.objc_msgSend(cls('NSTextField'), sel('labelWithString:'), nsstring(''))
    ObjC::SendId.objc_msgSend(label, sel('setFont:'), system_font)
    ObjC::SendId.objc_msgSend(label, sel('setTextColor:'), color(1.0, 1.0))
    ObjC::SendLong.objc_msgSend(label, sel('setAlignment:'), CENTERED)
    ObjC.msg_send_rect(label, sel('setFrame:'), SIDE_MARGIN, (HEIGHT - LINE_HEIGHT) / 2,
                       width - (SIDE_MARGIN * 2), LINE_HEIGHT)
    label
  end

  def system_font = ObjC::SendDoubles.objc_msgSend(cls('NSFont'), sel('systemFontOfSize:'), FONT_SIZE, 0.0)
  def cls(name) = ObjC.objc_getClass(name)
  def sel(name) = ObjC.sel_registerName(name)
  def color(white, alpha) = ObjC::SendDoubles.objc_msgSend(cls('NSColor'), sel('colorWithWhite:alpha:'), white, alpha)
  def nsstring(text) = ObjC::SendCString.objc_msgSend(cls('NSString'), sel('stringWithUTF8String:'), text)
end
