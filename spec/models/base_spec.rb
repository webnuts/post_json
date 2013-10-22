require 'spec_helper'

describe "Base model" do

  context "resolve to class" do
    subject { PostJson }

    it { expect { subject::Base.collection_name }.to raise_error(ArgumentError) }

    context "of same class instance" do
      subject { PostJson::Collection['SomeModel'] }

      it { subject.should equal(PostJson::Collection['SomeModel'])}
    end
  end

  context "should allow same primary key for different models" do
    let(:doc1) { PostJson::Collection['Customer'].create id: "abc"}
    let(:doc2) { PostJson::Collection['Order'].create id: "abc"}

    it { doc1.id.should == "abc" }
    it { doc1.id.should == doc2.id}
  end

  context "should not allow same primary key for more documents on same model" do
    before do
      PostJson::Collection['Customer'].create id: "abc"
    end

    it { expect { PostJson::Collection['Customer'].create(id: "abc") }.to raise_error(ActiveRecord::RecordNotUnique) }
  end

  context "should auto-assign primary key when nil" do
    subject { PostJson::Collection['Customer'].create }
    its(:id) { should match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)}
  end

  context "should auto-assign primary key when blank" do
    subject { PostJson::Collection['Customer'].create id: "    " }
    its(:id) { should match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)}
  end

  context "should strip primary key surrounded with whitespaces" do
    let(:new_id) { "a b  c" }
    subject { PostJson::Collection['Customer'].create id: "  #{new_id}  " }
    its(:id) { should == new_id }
  end

  context "should downcase primary key" do
    let(:new_id) { "abc" }
    let(:model) { PostJson::Collection['Customer'] }
    let!(:record) { model.create id: "#{new_id.upcase}" }
    subject { record }
    its(:id) { should == new_id }
    it { model.exists?(id: "#{new_id.upcase}").should be_true }
    it { model.where(id: "#{new_id.upcase}").count.should == 1 }
    it { model.find("#{new_id.upcase}").id.should == new_id }
  end

  context "should now allow change of primary key" do
    subject { PostJson::Collection['Customer'].create id: 1 }

    it { expect { subject.update_attribute('id', 2) }.to raise_error(ArgumentError) }
  end

  context "collection name" do
    let(:name) { "§!#¤%&" }
    subject { PostJson::Collection["   #{name}  "] }

    its(:collection_name) { should == name }

    context "changed" do
      let(:new_name) { "Customer" }
      before do
        subject.rename_collection("   #{new_name}      ")
      end

      its(:collection_name) { should == new_name }
    end
  end

  context "use timestamps" do
    let(:model) { PostJson::Collection['Customer'] }
    subject { model }

    its(:record_timestamps) { should be_true }

    context "and model attributes are not set" do
      subject { model.create(id: "abc") }

      its(:created_at) { should > 1.minute.ago }
      its(:created_at) { should < 1.minute.from_now }
      its(:updated_at) { should > 1.minute.ago }
      its(:updated_at) { should < 1.minute.from_now }
    end


    context "is disabled" do
      before do
        model.record_timestamps = false
      end

      its(:record_timestamps) { should be_false }

      context "and model attributes are not set" do
        subject { model.create(id: "abc") }

        its(:created_at) { should be_nil }
        its(:updated_at) { should be_nil }
      end
    end
  end

  context "move attributes to body" do
    subject { PostJson::Collection['Customer'].create(id: "abc", name: "Jacob") }

    it { subject.read_attribute('id').should == "abc" }
    it { subject.read_attribute('__doc__body')['id'].should == "abc" }
    it { subject.read_attribute('__doc__body')['name'].should == "Jacob" }
  end

  context "with unique cache key" do
    subject { PostJson::Collection['Customer'].create(id: "abc", name: "Jacob") }

    context "version number" do
      before do
        subject.update_column('__doc__version', 10)
      end

      let(:expected_cache_key) {"#{subject.class.name.underscore.dasherize}-#{subject.id}-version-#{subject.__doc__version}"}

      its(:cache_key) { should == expected_cache_key }
    end

    context "digest" do
      before do
        subject.update_column('__doc__version', nil)
      end
      let(:expected_cache_key) {"#{subject.class.name.underscore.dasherize}-#{subject.id}-version-#{Digest::MD5.hexdigest(subject.attributes.inspect)}"}

      its(:cache_key) { should == expected_cache_key }
    end
  end

  context "attributes" do
    let(:body) { {"id" => "abc", "name" => "Jacob"} }
    subject do
      PostJson::Collection['Customer'].record_timestamps = false
      PostJson::Collection['Customer'].include_version_number = false
      PostJson::Collection['Customer'].create(body)
    end

    its(:attributes) { should == body }
  end

  context "to hash" do
    let(:body) { {"id" => "abc", "name" => "Jacob"} }
    subject { PostJson::Collection['Customer'].create(body) }

    its(:to_h) { should == subject.attributes }
    its(:to_h) { should_not equal(subject.attributes) }
  end

  context "body attribute" do
    let(:body) { {"id" => "abc", "name" => "Jacob"} }
    let(:other_body) { {"id" => "abc", "name" => "Martin"} }
    subject do
      PostJson::Collection['Customer'].record_timestamps = false
      PostJson::Collection['Customer'].include_version_number = false
      PostJson::Collection['Customer'].create(body)
    end

    its(:__doc__body) { should == body }
    its(:__doc__body_was) { should == body }
    its(:__doc__body_change) { should be_nil }
    its(:__doc__body_changed?) { should be_false }
    it { subject.__doc__body_read_attribute('name').should == "Jacob" }
    it { subject.__doc__body_attribute_was('name').should == "Jacob" }
    it { subject.__doc__body_attribute_changed?('name').should be_false }
    it { subject['name'].should == "Jacob" }
    it { subject.attribute_changed?('name').should be_false }

    context "change" do
      before do
        #subject.write_attribute('__doc__body', other_body)
        subject.__doc__body_write_attribute('name', "Martin")
      end

      its(:__doc__body) { should == other_body }
      its(:__doc__body_was) { should == body }
      its(:__doc__body_change) { should == [body, other_body] }
      its(:__doc__body_changed?) { should be_true }
      it { subject.__doc__body_read_attribute('name').should == "Martin" }
      it { subject.__doc__body_attribute_was('name').should == "Jacob" }
      it { subject.__doc__body_attribute_changed?('name').should be_true }
      it { subject['name'].should == "Martin" }
      it { subject.attribute_changed?('name').should be_true }
    end

    context "unchange" do
      before do
        # subject.write_attribute('__doc__body', other_body)
        # subject.write_attribute('__doc__body', body)
        subject.__doc__body_write_attribute('name', "Martin")
        subject.__doc__body_write_attribute('name', "Jacob")
      end

      its(:__doc__body) { should == body }
      its(:__doc__body_was) { should == body }
      its(:__doc__body_change) { should be_nil }
      its(:__doc__body_changed?) { should be_false }
      it { subject.__doc__body_read_attribute('name').should == "Jacob" }
      it { subject.__doc__body_attribute_was('name').should == "Jacob" }
      it { subject.__doc__body_attribute_changed?('name').should be_false }
      it { subject['name'].should == "Jacob" }
      it { subject.attribute_changed?('name').should be_false }
    end

    context "nil as body" do
      before do
        subject.__doc__body = nil
      end

      its(:__doc__body) { should be_nil }
      its(:__doc__body_was) { should == body }
      its(:__doc__body_change) { should == [body, nil] }
      its(:__doc__body_changed?) { should be_true }
      it { subject.__doc__body_read_attribute('name').should be_nil }
      it { subject.__doc__body_attribute_was('name').should == "Jacob" }
      it { subject.__doc__body_attribute_changed?('name').should be_true }
      it { subject['name'].should be_nil }
      it { subject.attribute_changed?('name').should be_true }
    end
  end

  context "body attribute" do
    let(:body) { {"id" => "abc", "name" => "Jacob"} }
    subject { PostJson::Collection['Customer'].create(body) }

    its(:name) { should == "Jacob" }
    its(:name_changed?) { should be_false }
    its(:name_was) { should == "Jacob" }
    its(:name_change) { should be_nil }

    context "changed" do
      before do
        subject.name = "Martin"
      end      

      its(:name) { should == "Martin" }
      its(:name_changed?) { should be_true }
      its(:name_was) { should == "Jacob" }
      its(:name_change) { should == ["Jacob", "Martin"] }
    end
  end

  context "version enabled" do
    let(:body) { {"id" => "abc", "name" => "Jacob"} }
    subject { PostJson::Collection['Customer'].create(body) }

    its(:version) { should == 1 }

    context "after update with change" do
      before do
        subject.name = "Martin"
        subject.save
      end

      its(:version) { should == 2 }
    end

    context "after update without change" do
      before do
        subject.name = "Martin"
        subject.name = "Jacob"
        subject.save
      end

      its(:version) { should == 1 }
    end
  end

  context "version disabled" do
    let(:body) { {"id" => "abc", "name" => "Jacob"} }
    subject do
      PostJson::Collection['Customer'].include_version_number = false
      PostJson::Collection['Customer'].create(body)
    end

    its(:version) { should be_nil }

    context "after update with change" do
      before do
        subject.name = "Martin"
        subject.save
      end

      its(:version) { should be_nil }
    end

    context "after update without change" do
      before do
        subject.name = "Martin"
        subject.name = "Jacob"
        subject.save
      end

      its(:version) { should be_nil }
    end
  end

  context "model settings" do
    subject { PostJson::Collection['Customer'] }

    its(:meta) { should == {} }
    its(:record_timestamps) { should be_true }
    its(:created_at_attribute_name) { should == "created_at" }
    its(:updated_at_attribute_name) { should == "updated_at" }
    its(:include_version_number) { should be_true }
    its(:version_attribute_name) { should == "version" }
    its(:use_dynamic_index) { should be_true }
    its(:create_dynamic_index_milliseconds_threshold) { should == 50 }

    context "meta" do
      before { subject.meta = {"validate" => true} }
      its(:meta) { should == {"validate" => true} }
    end

    context "record_timestamps" do
      before { subject.record_timestamps = false }
      its(:record_timestamps) { should be_false }
    end

    context "created_at_attribute_name" do
      before { subject.created_at_attribute_name = "createdAt" }
      its(:created_at_attribute_name) { should == "createdAt" }
    end

    context "updated_at_attribute_name" do
      before { subject.updated_at_attribute_name = "updatedAt" }
      its(:updated_at_attribute_name) { should == "updatedAt" }
    end

    context "include_version_number" do
      before { subject.include_version_number = false }
      its(:include_version_number) { should be_false }
    end

    context "version_attribute_name" do
      before { subject.version_attribute_name = "lock_version" }
      its(:version_attribute_name) { should == "lock_version" }
    end

    context "use_dynamic_index" do
      before { subject.use_dynamic_index = false }
      its(:use_dynamic_index) { should be_false }
    end

    context "create_dynamic_index_milliseconds_threshold" do
      before { subject.create_dynamic_index_milliseconds_threshold = 111 }
      its(:create_dynamic_index_milliseconds_threshold) { should == 111 }
    end
  end

  context "dynamic indexes" do
    subject { PostJson::Collection['Customer'] }

    its(:dynamic_indexes) { should == [] }

    context "create index" do
      let(:selector) { "name" }
      before do
        subject.create_dynamic_index(selector)
      end
      its(:dynamic_indexes) { should == [selector] }

      context "and destroy index" do
        before do
          subject.destroy_dynamic_index(selector)
        end
        its(:dynamic_indexes) { should == [] }
      end
    end
  end

  context "json" do
    let(:body) { {"id" => "abc", "name" => "Jacob"} }
    let(:document) { PostJson::Collection['Customer'].create(body) }
    subject { JSON.parse(document.to_json) }

    it { subject.keys.sort.should == ["created_at", "id", "name", "updated_at", "version"] }
    it { subject["created_at"].should == document.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    it { subject["id"].should == document.id }
    it { subject["name"].should == document.name }
    it { subject["updated_at"].should == document.updated_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ') }
    it { subject["version"].should == document.version }
  end

  context "copy" do
    let(:orig_model) { PostJson::Collection["Originals"] }
    let(:copy_model) { orig_model.copy("Copies") }
    before do
      orig_model.create(id: "Jacob", age: 33)
      orig_model.create(id: "Martin", age: 29)
    end

    subject { copy_model }

    its(:count) { should == 2 }
    it { subject.find("Jacob").age.should == 33 }
    it { subject.find("Martin").age.should == 29 }

    context "conflict" do
      before do
        copy_model
        orig_model.create(id: "Jonathan", age: 33)
      end
      it { expect { orig_model.copy(copy_model.collection_name) }.to raise_error(ActiveRecord::RecordNotUnique) }
    end

    context "to existing collection" do
      let(:other_model) { PostJson::Collection["Others"] }
      before do
        other_model.create(id: "John", age: 25)
        other_model.copy(copy_model.collection_name)
        orig_model.create(id: "Jonathan", age: 33)
      end
      subject { copy_model }

      its(:count) { should == 3 }
      it { subject.find("Jacob").age.should == 33 }
      it { subject.find("Martin").age.should == 29 }
      it { subject.find("John").age.should == 25 }
    end
  end
end