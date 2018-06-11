module TableauDb
  class Sync

    SELECTED_CLASSES    = ['Customer', 'Network', 'Placement']

    def initialize
      @started_at    = Time.now
      @tableau_mysql = {host: "localhost", username: "root", password: ""}
    end

    def run
      SELECTED_CLASSES.each do |klass|
        puts "Copying #{klass}"
        selected_class = class_eval(klass.to_s)
        attrs          = tableau_attributes(selected_class)

        copy_to_tableau(selected_class, attrs)
      end

      puts "Process took #{(Time.now-@started_at).to_i} seconds"
    end

    private

    def tableau_attributes(klass)
      class_eval("Tableau::#{klass.to_s}").attribute_names
    end

    def copy_to_tableau(klass, attrs)
      object = klass.select(attrs)

      object.all.each do |obj|
        class_eval("Tableau::#{klass.to_s}").create_or_update(obj.attributes)
      end
    end
  end
end