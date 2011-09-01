class FileAttachment < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true

  has_attached_file :file, :url => "/files/attachments/:attachable_id/:id/:filename"

  delegate :url, :to => :file

  after_find { @original_path = file.path }
  after_save :relocate_file

  Paperclip.interpolates :attachable_id do |attachment, style|
    attachment.instance.attachable_id || 'unassigned'
  end

  def relocate_file
    return unless @original_path && @original_path != file.path

    Rails.logger.info "[file_attachment] moving #{@original_path} to #{file.path}"
    FileUtils.mkpath File.dirname(file.path)
    FileUtils.mv @original_path, file.path
    FileUtils.rmdir File.dirname(@original_path)
  end

  def image?
    (file.url =~ /\.(jpg|jpeg|gif|png|bmp)/) if file.present?
  end

  def filename
    File.basename(pretty_url)
  end

  def pretty_url
    file.url.split('?').first
  end
end
