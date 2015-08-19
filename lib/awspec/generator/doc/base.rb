require 'pp'

module Awspec::Generator
  module Doc
    class Base
      def generate_doc
        @matchers += collect_matchers - @ignore_matchers
        @matchers.sort! do |a, b|
          sort_num(a) <=> sort_num(b)
        end
        @describes += @ret.members.select do |describe|
          next true unless @ret[describe].is_a?(Array) || @ret[describe].is_a?(Hash)
        end if @ret.respond_to?(:members)
        its = @describes.map do |describe|
          'its(:' + describe.to_s + ')'
        end

        @descriptions = {}
        merge_file = File.dirname(__FILE__) + '/../../../../doc/_resource_types/' + @type_name.to_snake_case + '.md'
        if File.exist?(merge_file)
          matcher = nil
          File.foreach(merge_file) do |line|
            if /\A### (.+)\Z/ =~ line
              matcher = Regexp.last_match[1]
              next
            end
            @descriptions[matcher] = '' unless @descriptions[matcher]
            @descriptions[matcher] += line
          end
        end
        ERB.new(doc_template, nil, '-').result(binding)
      end

      def collect_matchers
        methods = @type.methods - Awspec::Helper::Finder.instance_methods - Object.methods
        methods.select! do |method|
          method.to_s.include?('?')
        end
        methods.map! do |method|
          next 'exist' if 'exists?' == method.to_s
          next 'have_' + Regexp.last_match[1] if /\Ahas_(.+)\?\z/ =~ method.to_s
          next 'be_' + Regexp.last_match[1] if /\A(.+)\?\z/ =~ method.to_s
          method.to_s
        end
      end

      def doc_template
        template = <<-'EOF'
## <a name="<%= @type_name.to_snake_case %>"><%= @type_name.to_snake_case %></a>

<%= @type_name %> resource type.
<% @matchers.each do |matcher| %>
### <%= matcher %>
<%- if @descriptions.include?(matcher) -%><%= @descriptions[matcher] %><%- end -%>
<% end %>
<%- unless its.empty? -%>#### <%= its.join(', ') %><%- end -%>

EOF
        template
      end

      def sort_num(str)
        case str
        when 'exist'
          0
        when /\Abe_/
          1
        when /\Ahave_/
          2
        else
          3
        end
      end
    end
  end
end