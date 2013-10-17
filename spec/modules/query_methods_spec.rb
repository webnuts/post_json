require 'spec_helper'

describe "Query Methods" do
  subject do
    klass = Class.new do
      include PostJson::QueryMethods
    end
    klass.new
  end

  its(:query_tree) { should == {} }
  its(:query_clone) { should_not equal(subject) }

  context "tree with context" do
    before do
      subject.query_tree[:original] = "tree"
    end

    its(:query_tree) { should == {original: "tree"} }
  end

  context "cloned tree" do
    before do
      subject.query_clone.query_tree[:original] = "tree"
    end
    
    its(:query_tree) { should == {} }
    it { subject.query_clone.class.should equal(subject.class)}
  end

  context "directly added query" do
    before do
      subject.add_query("directly", "works")
    end

    its(:query_tree) { should == {"directly" => ["works"]}}
  end

  context "except and only" do
    before do
      subject.offset!(1).limit!(1)
    end

    it { subject.except(:offset).query_tree.should == {limit: [1]}}
    it { subject.except(:limit).query_tree.should == {offset: [1]}}
    it { subject.only(:offset).query_tree.should == {offset: [1]}}
    it { subject.only(:limit).query_tree.should == {limit: [1]}}
  end

  it { subject.limit(1).query_tree.should == {limit: [1]}}
  it { subject.limit(1).limit(3).query_tree.should == {limit: [3]}}
  it { subject.offset(1).query_tree.should == {offset: [1]}}
  it { subject.offset(1).offset(3).query_tree.should == {offset: [3]}}
  it { subject.page(3, 25).query_tree.should == {limit: [25], offset: [50]}}
  it { subject.page(3, 25).page(2, 20).query_tree.should == {limit: [20], offset: [20]}}
  it { subject.order(:id).query_tree.should == {order:  ["id ASC"]}}
  it { subject.order("id desc").query_tree.should == {order:  ["id DESC"]}}
  it { subject.order(:id, :name).query_tree.should == {order:  ["id ASC", "name ASC"]}}
  it { subject.order([:id, :name]).query_tree.should == {order:  ["id ASC", "name ASC"]}}
  it { subject.order("id DESC", :name).query_tree.should == {order:  ["id DESC", "name ASC"]}}
  it { subject.order(:id).reorder(:name).query_tree.should == {order:  ["name ASC"]}}
  it { subject.order("id DESC", :name).reverse_order.query_tree.should == {order:  ["id ASC", "name DESC"]}}
  it { subject.where("function(doc) { return true; }").query_tree.should == {where_function: [{:function=>"function(doc) { return true; }", :arguments=>[]}]} }
  it { subject.where("name = ?", "Jacob").query_tree.should == {where_forward: [["name = ?", "Jacob"]]} }
  it { subject.where({name: "Jacob"}).query_tree.should == {where_equal: [{:attribute=>"name", :argument=>"Jacob"}]} }
  it { subject.where({person: {name: "Jacob"}}).query_tree.should == {where_equal: [{:attribute=>"person.name", :argument=>"Jacob"}]} }
  it { {p:{n:1,o:{c:2}}}.flatten_hash.should == {"p.n"=>1, "p.o.c"=>2} }
end

