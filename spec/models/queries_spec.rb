require 'spec_helper'

describe "Query" do
  let(:root_collection) { PostJson::Document.root }
  let(:named_collection)  { PostJson::Document.collection("devs") }
  
  context "empty root collection" do
    subject { root_collection }

    its(:any?) { should be_false }
    its(:blank?) { should be_true }
    its(:count) { should == 0 }
    it { subject.delete("not_exists").should == 0 }
    it { subject.delete_all.should == 0 }
    it { expect { subject.destroy("not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.destroy_all.should == [] }
    its(:empty?) { should be_true }
    its(:exists?) { should be_false }
    it { expect { subject.find("not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.find_by(id: "not_exists").should be_nil }
    it { expect { subject.find_by!(id: "not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    its(:first) { should be_nil }
    it { expect { subject.first! }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.first_or_create.id.should match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) }
    it { subject.first_or_create(name: "Jacob").name.should == "Jacob" }
    it { subject.where(age: 33).first_or_create.id.should match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) }
    it { subject.where(age: 33).first_or_create(name: "Jacob").to_h.slice(:age, :name).should == {"age" => 33, "name" => "Jacob"} }
    its(:ids) { should == [] }
    its(:last) { should be_nil }
    it { expect { subject.last! }.to raise_error(ActiveRecord::RecordNotFound) }
    its(:many?) { should be_false }
    its(:select) { should == [] }
    its(:size) { should == 0 }
    its(:take) { should be_nil }
    it { expect { subject.take! }.to raise_error(ActiveRecord::RecordNotFound) }
    its(:to_a) { should == [] }
    its(:pluck) { should == [] }
    its(:where_values_hash) { should == {} }
  end

  context "empty named collection" do
    subject { named_collection }

    its(:any?) { should be_false }
    its(:blank?) { should be_true }
    its(:count) { should == 0 }
    it { subject.delete("not_exists").should == 0 }
    it { subject.delete_all.should == 0 }
    it { expect { subject.destroy("not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.destroy_all.should == [] }
    its(:empty?) { should be_true }
    its(:exists?) { should be_false }
    it { expect { subject.find("not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.find_by(id: "not_exists").should be_nil }
    it { expect { subject.find_by!(id: "not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    its(:first) { should be_nil }
    it { expect { subject.first! }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.first_or_create.id.should match(/^devs\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) }
    it { subject.first_or_create(name: "Jacob").name.should == "Jacob" }
    it { subject.where(age: 33).first_or_create.id.should match(/^devs\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/) }
    it { subject.where(age: 33).first_or_create(name: "Jacob").to_h.slice(:age, :name).should == {"age" => 33, "name" => "Jacob"} }
    its(:ids) { should == [] }
    its(:last) { should be_nil }
    it { expect { subject.last! }.to raise_error(ActiveRecord::RecordNotFound) }
    its(:many?) { should be_false }
    its(:select) { should == [] }
    its(:size) { should == 0 }
    its(:take) { should be_nil }
    it { expect { subject.take! }.to raise_error(ActiveRecord::RecordNotFound) }
    its(:to_a) { should == [] }
    its(:pluck) { should == [] }
    its(:where_values_hash) { should == {} }
  end

  context "named collection with 1 document" do
    subject { named_collection }
    let(:doc_id) { "devs/123" }
    before do
      subject.create age: 33, name: "Jacob", id: doc_id
    end

    its(:any?) { should be_true }
    its(:blank?) { should be_false }
    its(:count) { should == 1 }
    it { subject.delete(doc_id).should == 1 }
    # failure: it { subject.delete_all.should == 1 }
    it { subject.destroy(doc_id)[0].id.should == doc_id }
    it { expect { subject.destroy("not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.destroy_all.length == 0 }
    it { subject.destroy_all[0].id.should == doc_id }
    its(:empty?) { should be_false }
    its(:exists?) { should be_true }
    it { subject.find(doc_id).id.should == doc_id }
    it { expect { subject.find("not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.find_by(id: doc_id).id.should == doc_id }
    it { subject.find_by(id: "not_exists").should be_nil }
    it { subject.find_by!(id: doc_id).id.should == doc_id }
    it { expect { subject.find_by!(id: "not_exists") }.to raise_error(ActiveRecord::RecordNotFound) }
    it { subject.first.id.should == doc_id }
    it { subject.first!.id.should == doc_id }
    it { subject.first_or_create.id.should == doc_id }
    it { subject.first_or_create(name: "Martin").name.should == "Jacob" }
    it { subject.where(age: 33).first_or_create.id.should == doc_id }
    it { subject.where(age: 33).first_or_create(name: "Martin").to_h.slice(:age, :name).should == {"age" => 33, "name" => "Jacob"} }
    its(:ids) { should == [doc_id] }
    it { subject.last.id.should == doc_id }
    its(:many?) { should be_false }
    its(:select) { should == [] }
    its(:size) { should == 1 }
    it { subject.take.id.should == doc_id }
    it { subject.take!.id.should == doc_id }
    it { subject.to_a[0].id.should == doc_id }
    its(:pluck) { should == [] }
    its(:where_values_hash) { should == {} }
  end

  context "named collection with 3 documents" do
    subject { named_collection }

    before do
      subject.create age: 33, name: "Jacob", details: {favorite: "green", height: 185}, id: "devs/"
      subject.create age: 33, name: "Jonathan", details: {favorite: "yellow", height: 186}, id: "devs/"
      subject.create age: 29, name: "Martin", details: {favorite: "blue", height: 187}, id: "devs/"
    end

    its(:count) { should == 3 }
    its(:exists?) { should == "1" }
    its(:empty?) { should == false }
    it { subject.limit(1).except(:limit).count.should == 3 }
    it { subject.offset(1).limit(1).except(:limit).count.should == 2 }
    it { subject.offset(1).limit(1).except(:offset).count.should == 1 }
    it { subject.offset(1).limit(1).except(:limit, :offset).count.should == 3 }
    it { expect { subject.page(-1, 2).count.should == 0 }.to raise_error(ActiveRecord::StatementInvalid) }
    it { subject.page(1, 2).count.should == 2 }
    it { subject.page(2, 2).count.should == 1 }
    it { subject.page(3, 2).count.should == 0 }
    it { subject.where("function(body) { return body['age'] == 33; }").count.should == 2 }
    it { subject.where("function(body, age) { return body['age'] == age; }", 29).count.should == 1 }
    it { subject.where("function(body, age) { return body['age'] == age; }", [29]).count.should == 1 }
    it { subject.where("function(body, age) { return body['age'] == age; }", "29").count.should == 1 }
    it { subject.where("function(body, age) { return body['age'] == age; }", ["29"]).count.should == 1 }
    it { subject.where("function(body) { return body['age'] == 33; }").where("function(body) { return body['name'] == 'Jacob'; }").count.should == 1 }
    it { subject.where('function(body) { return body["age"] == "33"; }').count.should == 2 }
    it { subject.where('function(body) { return body["name"] == "Jacob"; }').first.age.should == 33 }
    it { subject.order('age asc').first.name.should == "Martin" }
    it { subject.order('age desc').first.name.should == "Jacob" }
    it { subject.order('name asc').first.name.should == "Jacob" }
    it { subject.order('name desc').first.name.should == "Martin" }
    it { subject.order('name desc, age desc').select("name").should == [{"name"=>"Jonathan"}, {"name"=>"Jacob"}, {"name"=>"Martin"}] }
    it { subject.order('details.favorite desc').select("details.height").should == [{"details"=>{"height"=>186}}, {"details"=>{"height"=>185}}, {"details"=>{"height"=>187}}] }
    it { subject.order('name desc, details.favorite desc').select("details.height, name").should == [{"details"=>{"height"=>186}, "name"=>"Jonathan"}, {"details"=>{"height"=>185}, "name"=>"Jacob"}, {"details"=>{"height"=>187}, "name"=>"Martin"}] }
    it { expect { subject.order('name').page(-1, 2).select("name").should == [] }.to raise_error(ActiveRecord::StatementInvalid) }
    it { subject.order('name').page(1, 2).select("name").should == [{"name"=>"Jacob"}, {"name"=>"Jonathan"}] }
    it { subject.order('name').page(2, 2).select("name").should == [{"name"=>"Martin"}] }
    it { subject.order('name').page(3, 2).select("name").should == [] }
    it { subject.order('name').select({"person.name" => "name", "person.height" => "details.height"}).should == [{"person"=>{"name"=>"Jacob", "height"=>185}}, {"person"=>{"name"=>"Jonathan", "height"=>186}}, {"person"=>{"name"=>"Martin", "height"=>187}}] }
    it { subject.order('name').select({person: {first_name: :name, height: "details.height"}}).should == [{"person"=>{"first_name"=>"Jacob", "height"=>185}}, {"person"=>{"first_name"=>"Jonathan", "height"=>186}}, {"person"=>{"first_name"=>"Martin", "height"=>187}}] }
    it { subject.order(:name, :age).pluck("name, details.height").should == [["Martin", 187], ["Jacob", 185], ["Jonathan", 186]] }
    it { subject.order(:age).pluck(:age).should == [29, 33, 33] }
    it { subject.pluck.should == [] }
    it { subject.select.should == [] }
    it { subject.order(:name, :age).pluck(:age, :name).should == [[29, "Martin"], [33, "Jacob"], [33, "Jonathan"]] }
    it { subject.find(subject.first.id).should == subject.first }
    it { subject.find_by(age: 29).name.should == "Martin" }
    it { subject.find_by(name: "Martin").age.should == 29 }
    it { subject.find_by(age: 29, name: "Martin").age.should == 29 }
    it { subject.where(age: 29).pluck(:name).should == ["Martin"] }
    it { subject.where(age: "29", name: "Martin").pluck(:name).should == ["Martin"] }
    it { subject.where(details: {height: 187, favorite: "blue"}).pluck(:name).should == ["Martin"] }
    it { subject.order(:age).reverse.limit(1).pluck(:age).should == [33] }
    it { subject.order(:name, :age).reverse.limit(1).pluck(:name).should == ["Jonathan"] }
    it { subject.order(:age).last.age.should == 33 }
    it { subject.order("age desc").last.age.should == 29 }
    it { subject.order(:name).reverse.first.name.should == "Martin" }
    it { subject.order("name desc").reverse.first.name.should == "Jacob" }
    it { subject.order(:name, :age).last.name.should == "Jonathan" }
    it { subject.order(:name, "age desc").last.name.should == "Martin" }
    it { subject.where(details: {height: 185..186}).order('name').pluck('name').should == ["Jacob", "Jonathan"] }
    it { subject.where(details: {favorite: "blue".."green"}).order('name').pluck('name').should == ["Jacob", "Martin"] }


    context "and delete 1 document" do
      before do
        id = subject.first.id
        subject.delete(id)
      end
      its(:count) { should == 2 }
    end

    context "and delete 2 documents" do
      before do
        ids = subject.limit(2).pluck("id")
        subject.delete(ids)
      end
      its(:count) { should == 1 }
    end  
  end
end