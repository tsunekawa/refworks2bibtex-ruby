require 'bibtex'

class Refworks::
  class Document

    def self.load(filename)
        source = open(filename) do |f|
            self.parse(f.read)
        end

        source
    end

    def self.parse(text)
        hsh_ary = text.split("\n\n").map {|doc_source|
        doc_source.split("\n").inject(Hash.new) {|hsh, field|
            tokens = field.split("\s")
            tag    = tokens.shift
            value  = tokens.join(" ")

            hsh[tag] ||= Array.new
            hsh[tag] << value
            hsh
        }
        }
        
        docs = hsh_ary.map {|hsh|
        hsh.inject(self.new){|doc, tag_value|
            tag = tag_value[0]
            value = tag_value[1]

            if @@tags.keys.include? tag then
            doc.send "#{@@tags[tag]}=", value
            end

            doc
        }
        }

        docs
    end

    def self.convert_bibtex(refworks_documents)
        bib = ::BibTeX::Bibliography.new
        refworks_documents.each do |doc|
        bib << doc.convert_bibtex
        end

        bib
    end
        
    @@tags = {
        "RT" => :resource_type,
        "T1" => :primary_title,
        "A1" => :primary_authors,
        "A2" => :secondary_authors,
        "YR" => :publication_year,
        "LA" => :language,
        "ID" => :resource_id,
        "PB" => :publisher,
        "UL" => :ul
    }

    @@bibtex_resource_types = {
        "Magazine Article" => :article
    }

    attr_accessor *@@tags.values

    def convert_bibtex
        refworks_type = (self.resource_type || [:misc]).first.to_sym 
        type = @@bibtex_resource_types[refworks_type] || refworks_type
        ::BibTeX::Entry.new({
            :bibtex_type => type,
            :title => self.primary_title,
            :author => ( self.primary_authors + (self.secondary_authors || []) ).join(" and "),
            :year => self.publication_year,
            :publisher => self.publisher,
            :url => self.url
        })
    end
  end
end

if $0 == __FILE__ then
  filename = ARGV[0]
  refworks_documents = Refworks::Document.load(filename)
  export = Refworks::Document.convert_bibtex(refworks_documents)
  puts export.convert(:latex).to_s
end