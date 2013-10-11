require 'spec_helper'

describe "Collection" do
  let(:collection) { PostJson::Collection }
  subject { collection }

  context "initialize" do
    before do
      subject.initialize([{name: "Customers", use_timestamps: false}, {name: "Orders/", use_version_number: false}])
    end

    it { subject.where(name: "customers").first.use_timestamps.should be_false }
    it { subject.where(name: "orders").first.use_version_number.should be_false }
  end

  # context "empty database" do

  #   it { should respond_to(:create).with(2).arguments }
  #   it { should respond_to(:all_names).with(0).arguments }
  #   it { should respond_to(:[]).with(1).argument }
  #   it { should respond_to(:initialize).with(1).argument }
  #   it { should respond_to(:destroy_all!).with(0).arguments }
  #   it { should respond_to(:fake_it).with(1).argument }
  # end
end


