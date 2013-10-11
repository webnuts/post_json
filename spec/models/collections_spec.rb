require 'spec_helper'
require 'ostruct'

describe "Collections" do
  
  context "vanilla" do
    let(:collection) { PostJson::Collection.create }

    subject { collection }

    its(:name) { should == "" }
    its(:meta) { should == {} }
    its(:use_timestamps) { should be_true }
    its(:created_at_attribute_name) { should == "created_at" }
    its(:updated_at_attribute_name) { should == "updated_at" }
    its(:use_version_number) { should be_true }
    its(:version_attribute_name) { should == "version" }
    its(:use_dynamic_index) { should be_true }
    its(:create_dynamic_index_milliseconds_threshold) { should == 50 }
  end

  context "fixed naming" do
    it { PostJson::Collection.create(name: "Docs").name.should == "docs" }
    it { PostJson::Collection.create(name: "/Docs").name.should == "docs" }
    it { PostJson::Collection.create(name: "Docs/").name.should == "docs" }
    it { PostJson::Collection.create(name: "/Docs/").name.should == "docs" }
    it { PostJson::Collection.create(name: "Docs/Subs").name.should == "docs/subs" }
    it { PostJson::Collection.create(name: "/Docs/Subs").name.should == "docs/subs" }
    it { PostJson::Collection.create(name: "Docs/Subs/").name.should == "docs/subs" }
    it { PostJson::Collection.create(name: "/Docs/Subs/").name.should == "docs/subs" }
    it { PostJson::Collection.create(name: "Docs/Subs/Sabs").name.should == "docs/subs/sabs" }
    it { PostJson::Collection.create(name: "/Docs/Subs/Sabs").name.should == "docs/subs/sabs" }
    it { PostJson::Collection.create(name: "Docs/Subs/Sabs/").name.should == "docs/subs/sabs" }
    it { PostJson::Collection.create(name: "/Docs/Subs/Sabs/").name.should == "docs/subs/sabs" }
  end

  context "named" do
    let(:collection) { PostJson::Collection.create(name: "docs") }

    subject { collection }

    its(:name) { should == "docs" }
    its(:meta) { should == {} }
    its(:use_timestamps) { should be_true }
    its(:created_at_attribute_name) { should == "created_at" }
    its(:updated_at_attribute_name) { should == "updated_at" }
    its(:use_version_number) { should be_true }
    its(:version_attribute_name) { should == "version" }
    its(:use_dynamic_index) { should be_true }
    its(:create_dynamic_index_milliseconds_threshold) { should == 50 }
  end

  context "attribute setters with default settings" do
    let(:collection) { PostJson::Collection.create }

    subject { OpenStruct.new(new_record?: true) }

    before do
      subject.__doc__version = 123
      collection.update_document_attributes_on_save(subject)
    end

    its(:created_at) { should > 1.minute.ago }
    its(:created_at) { should < 1.minute.from_now }
    its(:updated_at) { should > 1.minute.ago }
    its(:updated_at) { should < 1.minute.from_now }
    its(:version) { should == subject.__doc__version }
  end

  context "attribute setters with disabled timestamps" do
    let(:collection) { PostJson::Collection.create(use_timestamps: false) }

    subject { OpenStruct.new(new_record?: true) }

    before do
      subject.__doc__version = 123
      collection.update_document_attributes_on_save(subject)
    end

    its(:created_at) { should be_nil }
    its(:updated_at) { should be_nil }
    its(:version) { should == subject.__doc__version }
  end

  context "attribute setters with disabled version" do
    let(:collection) { PostJson::Collection.create(use_version_number: false) }

    subject { OpenStruct.new(new_record?: true) }

    before do
      subject.__doc__version = 123
      collection.update_document_attributes_on_save(subject)
    end

    its(:created_at) { should > 1.minute.ago }
    its(:created_at) { should < 1.minute.from_now }
    its(:updated_at) { should > 1.minute.ago }
    its(:updated_at) { should < 1.minute.from_now }
    its(:version) { should be_nil }
  end

  context "attribute converting" do
    let(:collection) { PostJson::Collection.create }

    it do
      now = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      collection.convert_document_attribute_type("", now).should == Time.parse(now).in_time_zone
    end

    it do
      now = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      hash = {"key" => now}
      collection.convert_document_attribute_type("", hash).should == {"key" => Time.parse(now).in_time_zone}
    end

    it do
      now = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      array = [now]
      collection.convert_document_attribute_type("", array).should == [Time.parse(now).in_time_zone]
    end

    it do
      str = "just forward me"
      collection.convert_document_attribute_type("", "just forward me").should == str
    end
  end
end
