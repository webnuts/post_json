require 'spec_helper'

describe "Documents" do
  
  context "vanilla" do
    let(:document) { PostJson::Document.create(name: "MyDoc") }

    subject { document }

    its(:id) { should match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/) }
    its(:version) { should == 1 }
    its(:created_at) { should > 1.minute.ago }
    its(:created_at) { should < 1.minute.from_now }
    its(:updated_at) { should > 1.minute.ago }
    its(:updated_at) { should < 1.minute.from_now }
    its(:__doc__collection) {should be_a(PostJson::Collection)}
    its(:name) { should == "MyDoc" }

    context "json" do
      subject { JSON.parse(document.to_json) }

      it { subject.keys.sort.should == ["created_at", "id", "name", "updated_at", "version"] }
      it { subject["created_at"].should == document.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["id"].should == document.id }
      it { subject["name"].should == document.name }
      it { subject["updated_at"].should == document.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["version"].should == document.version }
    end

    context "collection" do
      subject { document.__doc__collection }

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
  end

  context "root" do
    let(:document) { PostJson::Document.create(id: "icecream", name: "MyDoc") }

    subject { document }

    its(:id) { should == "icecream" }
    its(:version) { should == 1 }
    its(:created_at) { should > 1.minute.ago }
    its(:created_at) { should < 1.minute.from_now }
    its(:updated_at) { should > 1.minute.ago }
    its(:updated_at) { should < 1.minute.from_now }
    its(:__doc__collection) {should be_a(PostJson::Collection)}
    its(:name) { should == "MyDoc" }

    context "json" do
      subject { JSON.parse(document.to_json) }

      it { subject.keys.sort.should == ["created_at", "id", "name", "updated_at", "version"] }
      it { subject["created_at"].should == document.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["id"].should == document.id }
      it { subject["name"].should == document.name }
      it { subject["updated_at"].should == document.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["version"].should == document.version }
    end

    context "collection" do
      subject { document.__doc__collection }

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
  end

  context "customers collection" do
    let(:document) { PostJson::Document.create(id: "customers/john", name: "MyDoc") }

    subject { document }

    its(:id) { should == "customers/john" }
    its(:version) { should == 1 }
    its(:created_at) { should > 1.minute.ago }
    its(:created_at) { should < 1.minute.from_now }
    its(:updated_at) { should > 1.minute.ago }
    its(:updated_at) { should < 1.minute.from_now }
    its(:__doc__collection) {should be_a(PostJson::Collection)}
    its(:name) { should == "MyDoc" }

    context "json" do
      subject { JSON.parse(document.to_json) }

      it { subject.keys.sort.should == ["created_at", "id", "name", "updated_at", "version"] }
      it { subject["created_at"].should == document.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["id"].should == document.id }
      it { subject["name"].should == document.name }
      it { subject["updated_at"].should == document.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["version"].should == document.version }
    end

    context "collection" do
      subject { document.__doc__collection }

      its(:name) { should == "customers" }
      its(:meta) { should == {} }
      its(:use_timestamps) { should be_true }
      its(:created_at_attribute_name) { should == "created_at" }
      its(:updated_at_attribute_name) { should == "updated_at" }
      its(:use_version_number) { should be_true }
      its(:version_attribute_name) { should == "version" }
      its(:use_dynamic_index) { should be_true }
      its(:create_dynamic_index_milliseconds_threshold) { should == 50 }
    end
  end

  context "update" do
    let(:document) { PostJson::Document.create(id: "icecream", name: "MyDoc") }
    let!(:version_1_created_at)  { document.created_at }
    let!(:version_1_updated_at)  { document.updated_at }

    before do
      document.name = "OtherDoc"
      document.number = 20
      sleep 0.01
      document.save
    end

    subject { document }

    its(:id) { should == "icecream" }
    its(:version) { should == 2 }
    its(:created_at) { should == version_1_created_at }
    its(:updated_at) { should > version_1_updated_at }
    its(:__doc__collection) {should be_a(PostJson::Collection)}
    its(:name) { should == "OtherDoc" }
    its(:number) { should == 20 }

    context "json" do
      subject { JSON.parse(document.to_json) }

      it { subject.keys.sort.should == ["created_at", "id", "name", "number", "updated_at", "version"] }
      it { subject["created_at"].should == document.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["id"].should == document.id }
      it { subject["name"].should == document.name }
      it { subject["updated_at"].should == document.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["version"].should == document.version }
      it { subject["number"].should == document.number }
    end

    context "collection" do
      subject { document.__doc__collection }

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

  end

  context "change" do
    let(:document) { PostJson::Document.create(id: "icecream", name: "MyDoc", some: "thing") }

    before do
      document.name = "OtherDoc"
      document.number = 20
      document.ignore = nil
    end

    subject { document }

    its(:id) { should == "icecream" }
    its(:version) { should == 1 }
    its(:created_at) { should > 1.minute.ago }
    its(:created_at) { should < 1.minute.from_now }
    its(:updated_at) { should > 1.minute.ago }
    its(:updated_at) { should < 1.minute.from_now }
    its(:__doc__collection) {should be_a(PostJson::Collection)}
    its(:name) { should == "OtherDoc" }
    its(:name_changed?) { should be_true }
    its(:number) { should == 20 }
    its(:number_changed?) { should be_true }
    its(:some) { should == "thing" }
    its(:some_changed?) { should be_false }
    its(:unknown) { should be_nil }
    its(:unknown_changed?) { should be_false }
    its(:ignore) { should be_nil }
    its(:ignore_changed?) { should be_false }

    context "json" do
      subject { JSON.parse(document.to_json) }

      it { subject.keys.sort.should == ["created_at", "id", "ignore", "name", "number", "some", "updated_at", "version"] }
      it { subject["created_at"].should == document.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["id"].should == document.id }
      it { subject["name"].should == document.name }
      it { subject["updated_at"].should == document.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
      it { subject["version"].should == document.version }
      it { subject["number"].should == document.number }
    end

    context "collection" do
      subject { document.__doc__collection }

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
  end

  context "not using timestamps" do
    let(:document) do
      collection = PostJson::Collection.create(name: "", use_timestamps: false)
      collection.documents.create(name: "MyDoc")
    end

    subject { document }

    it { subject.__doc__collection.use_timestamps.should be_false }
    its(:created_at) { should be_nil }
    its(:updated_at) { should be_nil }

    it do
      subject.number = 2
      subject.save
      subject.updated_at.should be_nil
    end

  end

end
