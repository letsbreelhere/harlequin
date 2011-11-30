Harlequin is a gem that allows easy access to the linear and quadratic discriminant analysis functions of R. To use harlequin, initialize a DiscriminantAnalysis object with an array of variable names for analysis, and a classification variable name as a second argument, like so:

```ruby
analysis = DiscriminantAnalysis.new([:weight, :height], :gender)
```

Training rows should be formatted as hashes with pairs of the form ```variable_name => value```. For example, we can add some rows to the analysis above with

```ruby
analysis.add_training_data(
                           { :weight => 200, :height => 72, :gender => 'male' },
                           { :weight => 205, :height => 71, :gender => 'male' },
                           { :weight => 140, :height => 63, :gender => 'female'},
                           { :weight => 130, :height => 61, :gender => 'female'}
                          )
```
(Note that there must be more than 1 of each classification value represented in the training data, and variable values must not be constant within a class.)

Initialize linear or quadratic analysis with ```#init_lda_analysis``` or ```#init_qda_analysis```, respectively. Then we can predict the class of new rows, also given as hashes:

```ruby
analysis.init_lda_analysis
analysis.predict(:weight => 180, :height => 68) #=> {:class=>"male", :confidence=>0.9999999999666846}
```

Multiple predictions can be computed at once in the same way as adding multiple training rows.

In order to assess the effectiveness of adding a variable, the DiscriminantAnalysis class includes access to the two-sample t-test for difference in means between classes. This currently works for binary classification only.

```ruby
analysis.t_test(:weight) #=> { :t_statistic=>12.0748, :degrees_of_freedom=>1.471, :p_value=>0.01898 }
```