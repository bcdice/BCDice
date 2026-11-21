require "rubocop"

module RuboCop
  module Cop
    module BCDice
      class GameSystemDependency < Base
        extend AutoCorrector

        MSG = "superclass file must be required: %<require_path>s".freeze

        def on_class(node)
          return unless processed_source.file_path.include?("bcdice/game_system/")

          _name, superclass, _body = *node
          return unless superclass

          parent_name = superclass.source

          return if ["Base", "StandardError"].include?(parent_name)

          # DiceTableのスーパークラスを利用している場合はOKとする
          # 本来はBase.rbのrequireを再帰的に確認するメソッドを実装すべきだが大変
          return if parent_name.start_with?("DiceTable::")

          # 同じファイル内でスーパークラスが定義されていたときは無視する
          return if processed_source.ast.each_node(:class).any? { |c| c.identifier.source == parent_name }

          require_path =
            if parent_name.include?("::")
              "bcdice/game_system/#{parent_name.split('::')[0]}"
            else
              "bcdice/game_system/#{parent_name}"
            end

          # requireが記述されているか確認
          return if require_present?(require_path)

          add_offense(node, message: format(MSG, require_path: require_path)) do |corrector|
            last_require = processed_source.ast.each_node(:send).select { |n| n.method?(:require) }.last
            if last_require
              corrector.insert_after(last_require, "\nrequire '#{require_path}'")
            else
              corrector.insert_before(processed_source.ast, "require '#{require_path}'\n\n")
            end
          end
        end

        private

        def require_present?(path)
          processed_source.ast.each_node(:send) do |node|
            next unless node.method?(:require)

            arg = node.first_argument
            return true if arg && arg.str_content == path
          end
          false
        end

        # dice_tableなどのスーパークラスの確認のために実装したが未使用
        def to_snake_case(str)
          str
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr("-", "_")
            .downcase
        end
      end
    end
  end
end
