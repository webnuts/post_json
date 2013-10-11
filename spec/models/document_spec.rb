require 'spec_helper'

describe "Document" do
  let(:document) { PostJson::Document.create }

  context "with nested accessor" do
    subject { document }

    before do
      document.details = {"color" => "blue", "gender" => "male"}
      document.save
    end

    its(:details) { should == {"color" => "blue", "gender" => "male"} }
    # failure: it { subject.details.color.should == "blue" }

    context "and cleared cache" do
      before do
        ActiveRecord::Base.connection.clear_query_cache
      end

      # failure: it { subject.details.color.should == "blue" }
    end
  end
end