class FileAttachmentAttachableIdNullAllowed < ActiveRecord::Migration
  def self.up
    change_column :file_attachments, :attachable_id,   :integer, :null => true
    change_column :file_attachments, :attachable_type, :string,  :null => true
    change_column :file_attachments, :attachment_type, :string,  :null => true
  end

  def self.down
    change_column :file_attachments, :attachable_id,   :integer, :null => false
    change_column :file_attachments, :attachable_type, :string,  :null => false
    change_column :file_attachments, :attachment_type, :string,  :null => false
  end
end
