require 'spec_helper'

describe "Collection" do
  context "meta" do
    let(:model) { PostJson::Collection["People"] }
    subject { model }
    its(:meta) { should == {} }
    its(:meta_some_attr) { should be_nil }

    context "attribute set" do
      before do
        model.meta_some_attr = 123
      end
      its(:meta) { should == {"some_attr" => 123} }
      its(:meta_some_attr) { should == 123 }

      context "to nil" do
        before do
          model.meta_some_attr = nil
        end
        its(:meta) { should == {"some_attr" => nil} }
        its(:meta_some_attr) { should be_nil }
      end
    end
  end

  context "new / persisted" do
    let(:model) { PostJson::Collection["People"] }
    subject { model }
    
    its(:new?) { should be_true }
    its(:persisted?) { should be_false }

    context "saved" do
      before do
        model.settings.save
      end

      its(:new?) { should be_false }
      its(:persisted?) { should be_true }

      context "and destroyed" do
        before do
          model.destroy!
        end        

        its(:new?) { should be_true }
        its(:persisted?) { should be_false }
      end
    end
  end
end


