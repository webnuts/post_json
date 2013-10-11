require 'spec_helper'

describe "Argument Methods" do
  subject do
    klass = Class.new do
      include PostJson::ArgumentMethods
    end
    klass.new
  end

  it { subject.join_arguments("   a , b   ").should == "a,b"}
  it { subject.join_arguments(["   a , b   "]).should == "a,b"}
  it { subject.join_arguments("   a    a ,   b    b ").should == "a a,b b"}
  it { subject.join_arguments(["   a    a ,   b    b "]).should == "a a,b b"}

end

