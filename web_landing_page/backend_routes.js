// Backend API endpoint for post landing pages
// Add this to your existing FounderVers web app backend

// Example: Node.js/Express implementation
const express = require('express');
const router = express.Router();

// GET /posts/:id/preview - Get post data for landing page
router.get('/posts/:id/preview', async (req, res) => {
  try {
    const postId = req.params.id;
    
    // Fetch post data from your database
    const post = await getPostById(postId);
    
    if (!post) {
      return res.status(404).json({
        error: 'Post not found',
        fallback: true
      });
    }
    
    // Format data for landing page
    const previewData = {
      id: post.id,
      title: post.title,
      description: truncateDescription(post.content, 150),
      image_url: post.image_url,
      author: {
        name: post.author.name,
        role: post.author.role || 'Entrepreneur',
        initials: getInitials(post.author.name),
        avatar_url: post.author.avatar_url
      },
      stats: {
        comments: post.comment_count || 0,
        likes: post.like_count || 0,
        shares: post.share_count || 0
      },
      created_at: post.created_at,
      app_store_urls: {
        ios: process.env.IOS_APP_STORE_URL,
        android: process.env.ANDROID_PLAY_STORE_URL
      }
    };
    
    // Track preview view for analytics
    await trackEvent('landing_page_data_served', {
      post_id: postId,
      user_agent: req.get('User-Agent'),
      referrer: req.get('Referrer')
    });
    
    res.json(previewData);
    
  } catch (error) {
    console.error('Error fetching post preview:', error);
    res.status(500).json({
      error: 'Internal server error',
      fallback: true
    });
  }
});

// POST /posts/:id/share - Generate shareable link
router.post('/posts/:id/share', async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.user?.id; // From auth middleware
    
    // Generate unique share URL with tracking
    const shareId = generateUniqueId();
    const shareUrl = `https://foundervers.com/posts/${postId}?share_id=${shareId}&ref=${userId || 'anonymous'}`;
    
    // Store share record for analytics
    await createShareRecord({
      id: shareId,
      post_id: postId,
      shared_by_user_id: userId,
      share_url: shareUrl,
      created_at: new Date()
    });
    
    // Update post share count
    await incrementShareCount(postId);
    
    res.json({
      shareUrl,
      shareId,
      success: true
    });
    
  } catch (error) {
    console.error('Error generating share URL:', error);
    res.status(500).json({
      error: 'Failed to generate share URL',
      shareUrl: `https://foundervers.com/posts/${req.params.id}` // Fallback
    });
  }
});

// GET /posts/:id - Main landing page route
router.get('/posts/:id', async (req, res) => {
  try {
    const postId = req.params.id;
    const shareId = req.query.share_id;
    const referrer = req.query.ref;
    
    // Track landing page visit
    await trackEvent('landing_page_visited', {
      post_id: postId,
      share_id: shareId,
      referrer: referrer,
      user_agent: req.get('User-Agent'),
      ip_address: req.ip
    });
    
    // Serve the landing page HTML
    res.sendFile(path.join(__dirname, '../public/post_landing.html'));
    
  } catch (error) {
    console.error('Error serving landing page:', error);
    res.status(500).send('Error loading page');
  }
});

// Helper functions
function truncateDescription(text, maxLength) {
  if (!text || text.length <= maxLength) return text;
  return text.substring(0, maxLength).replace(/\s+\S*$/, '') + '...';
}

function getInitials(name) {
  if (!name) return 'FV';
  return name.split(' ')
    .map(word => word.charAt(0).toUpperCase())
    .slice(0, 2)
    .join('');
}

function generateUniqueId() {
  return Math.random().toString(36).substring(2, 15) + 
         Math.random().toString(36).substring(2, 15);
}

async function getPostById(postId) {
  // Replace with your database query
  // Example for different databases:
  
  // PostgreSQL/Supabase:
  // const { data } = await supabase
  //   .from('posts')
  //   .select(`
  //     *,
  //     author:profiles(name, role, avatar_url),
  //     comment_count:comments(count),
  //     like_count:likes(count)
  //   `)
  //   .eq('id', postId)
  //   .single();
  
  // MongoDB:
  // const post = await Post.findById(postId)
  //   .populate('author', 'name role avatar_url')
  //   .lean();
  
  // For now, return mock data structure
  return {
    id: postId,
    title: 'Revolutionary AI Startup Idea',
    content: 'This is a detailed post about an innovative AI startup concept...',
    image_url: null,
    author: {
      name: 'Alex Founder',
      role: 'Serial Entrepreneur',
      avatar_url: null
    },
    comment_count: 23,
    like_count: 127,
    share_count: 8,
    created_at: new Date()
  };
}

async function createShareRecord(shareData) {
  // Store in your database
  console.log('Creating share record:', shareData);
}

async function incrementShareCount(postId) {
  // Update post share count
  console.log('Incrementing share count for post:', postId);
}

async function trackEvent(eventName, properties) {
  // Send to your analytics service
  console.log('Analytics:', eventName, properties);
}

module.exports = router;
