module Harlequin
  require 'rinruby'
  
  R.echo false
  R.eval "library(MASS)"
  R.eval "library(alr3)"
  R.eval "library(RWeka)"

  class DiscriminantAnalysis
    attr_reader :training_data, :variables, :classification_variable, :accuracy, :class_hash

    def initialize(variables, classification_variable)
      @accuracy                = nil
      @variables               = variables << classification_variable
      @classification_variable = classification_variable
      @training_data           = []
      @class_hash              = {}
      @current_analysis_type   = nil
    end
  
    def clear_training_data
      @training_data = []
      @class_hash    = {}
    end

    def add_training_data(*new_data)
      @training_data += new_data
    
      @training_data.map { |row| row[@classification_variable] }.each do |class_value|
        unless @class_hash.keys.include? class_value
          @class_hash.merge!({ class_value => (@class_hash.values.max ? @class_hash.values.max+1 : 1) })
        end
      end
    end
  
    # Returns the classification for an array of sample points.
    def predict(*samples)
      (variables - [classification_variable]).each do |var|
        R.assign(var.to_s + "_sample", samples.map { |s| s[var] })
      end
      
      sample_var_declarations = (variables - [classification_variable]).map { |var| "#{var.to_s} = #{var.to_s}_sample" }.join(',')
      
      if @current_analysis_type == :k_nearest_neighbor
        R.eval <<-EOF
        sample_points <- data.frame(#{sample_var_declarations})
        
        predictions <- predict(fit, sample_points)
        classes <- round(predictions)
        d <- data.frame(classes, confidence=predictions)
        EOF
        
        prediction_matrix = R.pull "classes"
        predictions = prediction_matrix.map do |row|
          classification = row.to_i
          {
            :class => @class_hash.invert[classification]
          }
        end
        
        predictions.count == 1 ? predictions.first : predictions
      else
        R.eval <<-EOF
        sample_points <- data.frame(#{sample_var_declarations})
        
        predictions <- predict(fit, sample_points)
        classes <- as.numeric(predictions$class)
        
        d <- data.frame(classes, confidence=predictions$posterior)
        EOF
        
        prediction_matrix = R.pull "as.matrix(d)"
        predictions = prediction_matrix.to_a.map do |row|
          classification = row.first.to_i
          confidence = row[classification]
          {
            :class      => @class_hash.invert[classification],
            :confidence => confidence
          }
        end
        
        predictions.count == 1 ? predictions.first : predictions
      end
    end
  
    # Performs a test of difference of means between classes
    # Since the t-test is two-sample, classification_variable must only have two states
    def t_test(variable)
      R.eval "t_test <- t.test(#{variable.to_s} ~ #{classification_variable.to_s})"
    
      t_statistic        = R.pull "t_test$statistic"
      degrees_of_freedom = R.pull "t_test$parameter"
      p_value            = R.pull "t_test$p.value"
    
      {
        :t_statistic        => t_statistic,
        :degrees_of_freedom => degrees_of_freedom,
        :p_value            => p_value
      }
    end
  
    def plot(samples = nil)
      if samples
        variables.each do |var|
          R.assign("#{var}_sample", samples.map { |s| s[var] })
        end
        plot_vars = (variables - [classification_variable]).map { |var| "#{var}_sample" }.join(',')        
      else
        plot_vars = (variables - [classification_variable]).map { |var| "analysis_data$#{var}" }.join(',')
      end
      R.eval "plot(data.frame(#{plot_vars}), col=as.numeric(#{classification_variable.to_s}))"
    end
  
    def plot_predict(samples = nil)
      if samples
        variables.each do |var|
          R.assign("#{var}_sample", samples.map { |s| s[var] })
        end
        plot_vars = (variables - [classification_variable]).map { |var| "#{var}_sample" }.join(',')
      
        R.predictions = samples.map { |sample| predict(sample) }
      else
        plot_vars = (variables - [classification_variable]).map { |var| "analysis_data$#{var}" }.join(',')
        R.eval "predictions <- as.numeric(analysis_data$#{classification_variable.to_s})"
      end
      R.eval "plot(data.frame(#{plot_vars}), col=predictions)"
    end
  
    ['lda', 'qda'].each do |analysis_type|
      define_method("init_#{analysis_type}_analysis") do
        init_analysis
        R.eval <<-EOF
          analysis_data <- data.frame(#{@var_declarations})
          fit <- #{analysis_type}(#{classification_variable.to_s} ~ #{@non_class_variables}, data=analysis_data)
        EOF
        
        @current_analysis_type = analysis_type.to_sym
        compute_accuracy
      end
    end
    
    def init_knn_analysis
      init_analysis
      R.eval <<-EOF
        analysis_data <- data.frame(#{@var_declarations})
        fit <- IBk(#{classification_variable.to_s} ~ ., data=analysis_data)
      EOF
      
      @current_analysis_type = :k_nearest_neighbor
      compute_accuracy
    end
  
    private
  
    def init_analysis
      variables.each do |variable|
        if variable == @classification_variable
          R.assign(variable.to_s, training_data.map { |point| @class_hash[point[variable]] })
        else
          R.assign(variable.to_s, training_data.map { |point| point[variable] })
        end
      end
      @var_declarations = variables.map(&:to_s).join(',')
      @non_class_variables = (variables - [classification_variable]).map { |variable| variable.to_s }.join('+')
    end
    
    def compute_accuracy
      if @current_analysis_type == :k_nearest_neighbor
        R.eval "ct <- table(predict(fit), analysis_data$#{classification_variable.to_s})"
      else
        R.eval "ct <- table(predict(fit)$class, analysis_data$#{classification_variable.to_s})"
      end
      
      percent_correct = R.pull "sum(diag(prop.table(ct)))"
      percent_false_positives = (R.pull "prop.table(ct)[1,2]") / (R.pull "prop.table(ct)[1,1] + prop.table(ct)[1,2]")
      percent_false_negatives = (R.pull "prop.table(ct)[2,1]") / (R.pull "prop.table(ct)[2,1] + prop.table(ct)[2,2]")
    
      correlation_coefficient = R.pull "sqrt(chisq.test(ct)$statistic/sum(ct))"
    
      @accuracy = {
        :percent_correct         => percent_correct,
        :percent_false_negatives => percent_false_negatives,
        :percent_false_positives => percent_false_positives,
        :correlation_coefficient => correlation_coefficient
      }
    end
  end
end

include Harlequin
