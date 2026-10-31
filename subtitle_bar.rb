# frozen_string_literal: true

# A borderless window along the bottom of the screen, built by sending Objective-C messages.
class SubtitleBar
  # Objective-C has one entry point, objc_msgSend, declared once per message shape.
  module AppKit
    extend FFI::Library

    ffi_lib 'objc'
    ffi_cflags '-framework AppKit'

    attach_function :objc_getClass,    [:str], :ptr
    attach_function :sel_registerName, [:str], :ptr
    attach_function :msg,        :objc_msgSend, %i[ptr ptr], :ptr
    attach_function :msg_object, :objc_msgSend, %i[ptr ptr ptr], :ptr
    attach_function :msg_string, :objc_msgSend, %i[ptr ptr str], :ptr
    attach_function :msg_int,    :objc_msgSend, %i[ptr ptr long], :ptr
    attach_function :msg_floats, :objc_msgSend, %i[ptr ptr double double], :ptr
    # On Apple Silicon an NSRect travels as four doubles.
    attach_function :msg_frame,      :objc_msgSend, %i[ptr ptr double double double double], :ptr
    attach_function :msg_new_window, :objc_msgSend, %i[ptr ptr double double double double long long long], :ptr
    attach_function :main_display,  :CGMainDisplayID,     [], :uint32
    attach_function :display_width, :CGDisplayPixelsWide, [:uint32], :size_t
  end

  HEIGHT = 120.0
  FONT_SIZE = 44.0
  LINE_HEIGHT = 54.0
  SIDE_MARGIN = 40.0
  BORDERLESS = 0
  BUFFERED = 2
  ABOVE_NORMAL_WINDOWS = 25
  CENTERED = 1

  def initialize
    AppKit.msg(cls('NSApplication'), sel('sharedApplication'))
    width = AppKit.display_width(AppKit.main_display).to_f
    window = new_window(width)
    @label = new_label(width)
    AppKit.msg_object(AppKit.msg(window, sel('contentView')), sel('addSubview:'), @label)
    AppKit.msg(window, sel('orderFrontRegardless'))
  end

  def show(text)
    AppKit.msg_object(@label, sel('setStringValue:'), nsstring(text))
  end

  private

  def new_window(width)
    window = AppKit.msg_new_window(AppKit.msg(cls('NSWindow'), sel('alloc')),
                                   sel('initWithContentRect:styleMask:backing:defer:'),
                                   0.0, 0.0, width, HEIGHT, BORDERLESS, BUFFERED, 0)
    AppKit.msg_int(window, sel('setOpaque:'), 0)
    AppKit.msg_object(window, sel('setBackgroundColor:'), color(0.0, 0.7))
    AppKit.msg_int(window, sel('setLevel:'), ABOVE_NORMAL_WINDOWS)
    AppKit.msg_int(window, sel('setIgnoresMouseEvents:'), 1)
    window
  end

  def new_label(width) # rubocop:disable Metrics/AbcSize
    label = AppKit.msg_object(cls('NSTextField'), sel('labelWithString:'), nsstring(''))
    AppKit.msg_object(label, sel('setFont:'), system_font)
    AppKit.msg_object(label, sel('setTextColor:'), color(1.0, 1.0))
    AppKit.msg_int(label, sel('setAlignment:'), CENTERED)
    AppKit.msg_frame(label, sel('setFrame:'), SIDE_MARGIN, (HEIGHT - LINE_HEIGHT) / 2,
                     width - (SIDE_MARGIN * 2), LINE_HEIGHT)
    label
  end

  def system_font = AppKit.msg_floats(cls('NSFont'), sel('systemFontOfSize:'), FONT_SIZE, 0.0)
  def cls(name) = AppKit.objc_getClass(name)
  def sel(name) = AppKit.sel_registerName(name)
  def color(white, alpha) = AppKit.msg_floats(cls('NSColor'), sel('colorWithWhite:alpha:'), white, alpha)
  def nsstring(text) = AppKit.msg_string(cls('NSString'), sel('stringWithUTF8String:'), text)
end
