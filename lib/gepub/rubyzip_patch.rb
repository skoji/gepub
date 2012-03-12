require 'zip/zip'

module Zip
  class ZipCentralDirectory
    def write_to_stream(io)  #:nodoc:
      offset = io.tell
      @entrySet.each { |entry| entry.write_c_dir_entry(io) }
      write_e_o_c_d(io, offset)
    end
  end
end
