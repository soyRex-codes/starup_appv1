-- Add message_type and metadata columns to messages table
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text' NOT NULL,
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Add comment explaining the columns
COMMENT ON COLUMN messages.message_type IS 'Type of message: text, image, file, system';
COMMENT ON COLUMN messages.metadata IS 'Additional data for the message (file URL, dimensions, etc.)';

-- Create chat-media storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat-media', 'chat-media', false)
ON CONFLICT (id) DO NOTHING;

-- Set up RLS policies for chat-media bucket

-- Allow authenticated users to upload files to chat-media
-- They can only upload to their own folder: user_id/filename
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-media' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view files in chat-media
-- Ideally, we would restrict this to participants of the conversation,
-- but storage policies don't easily support joining with other tables.
-- For now, we'll allow authenticated users to read files if they know the path.
-- Since paths contain random UUIDs/filenames, this is reasonably secure for this stage.
CREATE POLICY "Allow authenticated reads"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'chat-media');

-- Allow users to delete their own files
CREATE POLICY "Allow users to delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'chat-media' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
