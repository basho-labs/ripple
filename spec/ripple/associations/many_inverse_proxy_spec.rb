require 'spec_helper'

describe Ripple::Associations::ManyInverseProxy do

  before :each do
    @comment = Comment.create
  end

  after do
    Like.destroy_all
    Comment.destroy_all
  end

  it "should be empty when there aren't objects associated" do
    @comment.likes.should be_empty
    @comment.dislikes.should be_empty
  end

  it "should list objects who stored the @comment.key" do
    like = Like.create(liked_comment: @comment)
    @comment.reload

    like.liked_comment.should == @comment
    like.liked_comment_id.should == @comment.key
    @comment.likes.size.should == 1
    @comment.likes.should include(like)

    bad_comment = Comment.create
    dislike = Like.create(disliked_comment_id: bad_comment.key, positive: false)

    bad_comment.reload
    dislike.disliked_comment.should == bad_comment
    dislike.disliked_comment_id.should == bad_comment.key
    bad_comment.dislikes.size.should == 1
    bad_comment.dislikes.should include(dislike)
  end

  it "should update foreign key on association" do
    other_comment = Comment.create
    like1 = Like.create(liked_comment: @comment)
    like2 = Like.create(liked_comment: other_comment)
    like3 = Like.create

    like1.liked_comment.should_not be_nil
    @comment.likes.size.should == 1
    other_comment.likes.size.should == 1

    @comment.likes = [like2, like3]
    @comment.save
    [like1, like2, like3].each(&:reload)
    other_comment.reload

    like1.liked_comment.should be_nil
    like2.liked_comment.should == @comment
    like3.liked_comment.should == @comment
    @comment.likes.size.should == 2
    other_comment.likes.should be_empty
  end
end
