class Post
  include Ripple::Document
  property :comment_keys, Array
  property :user_key, String
  property :title, String

  one :user,      using: :stored_key
  many :comments, using: :stored_key
end

class Comment
  include Ripple::Document

  many :likes, using: :inverse, of: :liked_comment
  many :dislikes, class_name: 'Like', using: :inverse, of_key: :disliked_comment_id
end

class Like
  include Ripple::Document

  property :positive,            Boolean, default: true
  property :user_key,            String
  property :liked_comment_id,    String, index: true
  property :disliked_comment_id, String, index: true

  one :user,             using: :stored_key
  one :liked_comment,    class_name: 'Comment', using: :stored_key, foreign_key: :liked_comment_id
  one :disliked_comment, class_name: 'Comment', using: :stored_key, foreign_key: :disliked_comment_id
end
