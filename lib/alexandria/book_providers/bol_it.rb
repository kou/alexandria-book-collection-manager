# Copyright (C) 2007 Marco Costantini
# based on ibs_it.rb by Claudio Belotti
#
# Alexandria is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# Alexandria is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with Alexandria; see the file COPYING.  If not,
# write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

require 'fileutils'
require 'net/http'
require 'open-uri'
#require 'cgi'

module Alexandria
class BookProviders
    class BOL_itProvider < GenericProvider
        BASE_URI = "http://www.bol.it"
        CACHE_DIR = File.join(Alexandria::Library::DIR, '.bol_it_cache')
        REFERER = "http://www.bol.it"
        def initialize
            super("BOL_it", "BOL Italia")
            FileUtils.mkdir_p(CACHE_DIR) unless File.exists?(CACHE_DIR)            
            # no preferences for the moment
            at_exit { clean_cache }
        end
        
        def search(criterion, type)
            req = BASE_URI + "/libri/"
            req += case type
                when SEARCH_BY_ISBN
                    "scheda/"

                when SEARCH_BY_TITLE
                    "risultatoricerca?action=bolrisultatoricerca&skin=bol&filtro_ricerca=BOL&quick_type=Titolo&titolo="

                when SEARCH_BY_AUTHORS
                    "risultatoricerca?action=bolrisultatoricerca&skin=bol&filtro_ricerca=BOL&quick_type=Autore&titolo="

                when SEARCH_BY_KEYWORD
                    "risultatoricerca?action=bolrisultatoricerca&skin=bol&filtro_ricerca=BOL&quick_type=Parola%20chiave&titolo="

                else
                    raise InvalidSearchTypeError

            end
            
if type == SEARCH_BY_ISBN
## warning: this provider uses pages like http://www.bol.it/libri/scheda/ea978888584104 with 12 numbers, without the checksum
            req += "ea978" + Library.canonicalise_isbn(criterion)[0 .. 8] + ".html"
else
            req += CGI.escape(criterion)
end
            p req if $DEBUG
	        data = transport.get(URI.parse(req))
            if type == SEARCH_BY_ISBN
                to_book(data) rescue raise NoResultsError
            else
                begin
                    results = [] 
                    each_book_page(data) do |code, title|
                        results << to_book(transport.get(URI.parse("http://www.bol.it/libri/scheda/ea978" + code)))
                    end
                    return results 
                rescue
                    raise NoResultsError
                end
            end
        end

        def url(book)
            return nil unless book.isbn
            "http://www.bol.it/libri/scheda/ea978" + Library.canonicalise_isbn(book.isbn)[0 .. 8] + ".html"
        end

        #######
        private
        #######
    
        def to_book(data)
            raise unless md = /<INPUT type =hidden name ="mailTitolo" value="([^"]+)/.match(data)
            title = CGI.unescape(md[1].strip)
            authors = []
	    
	  if md = /<INPUT type =HIDDEN name ="mailAutore" value="([^"]+)/.match(data)
            md[1].split(', ').each { |a| authors << CGI.unescape(a.strip) }
          end

            raise unless md = /<INPUT type =HIDDEN name ="mailEAN" value="([^"]+)/.match(data)
            isbn = md[1].strip
            isbn += String( Library.ean_checksum( Library.extract_numbers( isbn ) ) )

            raise unless md = /<INPUT type =HIDDEN name ="mailEditore" value="([^"]+)/.match(data)
	        publisher = CGI.unescape(md[1].strip)

            raise unless md = /<INPUT type =HIDDEN name ="mailFormato" value="([^"]+)/.match(data)
            edition = CGI.unescape(md[1].strip)
            if md = /\&nbsp\;\|\&nbsp\;([^&]+)\&nbsp\;\|\&nbsp\;/.match(data) and md[1] != "0"
                edition = CGI.unescape(md[1].strip) + " p., " + edition
            end

            publish_year = nil
            if md = /<INPUT type =HIDDEN name ="mailAnnoPubbl" value="([^"]+)/.match(data)
                publish_year = CGI.unescape(md[1].strip).to_i
                publish_year = nil if publish_year == 0
            end
          
            cover_url = "http://www.bol.it/bol/includes/tornaImmagine.jsp?cdSoc=BL&ean=" + isbn[0 .. 11] + "&tipoOggetto=PIB&cdSito=BL" 
            cover_filename = isbn + ".tmp"
            Dir.chdir(CACHE_DIR) do
                File.open(cover_filename, "w") do |file|
                    file.write open(cover_url, "Referer" => REFERER ).read
                end                    
            end

            medium_cover = CACHE_DIR + "/" + cover_filename
            if File.size(medium_cover) > 0
                puts medium_cover + " has non-0 size" if $DEBUG
                return [ Book.new(title, authors, isbn, publisher, publish_year, edition),medium_cover ]
            end
            puts medium_cover + " has 0 size, removing ..." if $DEBUG
            File.delete(medium_cover)
            return [ Book.new(title, authors, isbn, publisher, publish_year, edition) ]
        end

        def each_book_page(data)
	        raise if data.scan(/<a href="\/libri\/scheda\/ea978([\d]+).html">/) { |a| yield a}.empty?
        end
    
        def clean_cache
            #FIXME begin ... rescue ... end?
            Dir.chdir(CACHE_DIR) do
                Dir.glob("*.tmp") do |file|
                    puts "removing " + file if $DEBUG
                    File.delete(file)    
                end
            end
        end
    end
end
end

