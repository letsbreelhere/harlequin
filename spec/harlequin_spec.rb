require 'spec_helper'
describe Harlequin::DiscriminantAnalysis do
  before do
    @discriminant_analysis = DiscriminantAnalysis.new([:weight, :height], :gender)

    csv_data = CSV.read("spec/lda_sample.csv")
    csv_data.shift
    @training = csv_data.map { |weight, height, gender| {:weight => weight.to_f, :height => height.to_f, :gender => gender.to_i} }

    @discriminant_analysis.add_training_data(*@training)
    @discriminant_analysis.init_lda_analysis
    
    @male_sample   = { :height => 73, :weight => 210 }
    @female_sample = { :height => 60, :weight => 140 }
    
    @male_prediction   = @discriminant_analysis.predict(@male_sample)
    @female_prediction = @discriminant_analysis.predict(@female_sample)
  end
  
  it 'computes the accuracy of a given training set' do
    @discriminant_analysis.accuracy[:percent_correct].should be > 0.5
  end
  
  it 'predicts inclusion in a set' do
    @male_prediction[:class].should eq(1)
    @female_prediction[:class].should eq(2)
  end
  
  it 'provides confidence scores for a prediction' do
    @male_prediction[:confidence].should be > 0.5
    @female_prediction[:confidence].should be > 0.5
  end
  
  it 'predicts for arrays of sample points' do
    samples = [@male_sample, @female_sample]
    predictions = @discriminant_analysis.predict(*samples)
    
    predictions.map { |row| row[:class] }.should eq [1,2]
    predictions.map { |row| row[:confidence] }.each do |confidence|
      confidence.should be > 0.5
    end
  end
  
  it 'predicts for k-nearest neighbor classifiers' do
    @discriminant_analysis.init_knn_analysis
    samples = [@male_sample, @female_sample]
    predictions = @discriminant_analysis.predict(*samples)
    
    predictions.map { |row| row[:class] }.should eq [1,2]
  end
  
  it 'clears training data from a DiscriminantAnalysis instance' do
    @discriminant_analysis.clear_training_data
    @discriminant_analysis.training_data.should be_empty
  end
  
  it 'accepts non-numeric classification values in training data' do
    @discriminant_analysis.clear_training_data
    
    @training.map! do |row|
      gender_string = row[:gender] == 1 ? 'male' : 'female'
      row.merge(:gender => gender_string)
    end
    
    @discriminant_analysis.add_training_data(*@training)
    @discriminant_analysis.init_lda_analysis
    @discriminant_analysis.accuracy[:percent_correct].should be_within(0.001).of 0.9485
    
    @male_prediction = @discriminant_analysis.predict(@male_sample)
    @male_prediction[:class].should eq 'male'
  end
end
