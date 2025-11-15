# Admin System - FounderVers Mobile App

## Overview
The admin system provides comprehensive management capabilities for the FounderVers platform, allowing designated administrators to have unlimited access to all features, content management, and user controls.

## Features

### 🔐 Admin Authentication
- Role-based access control
- Secure admin identification via email whitelist
- Session management for admin users

### 📊 Dashboard Overview
- System analytics and metrics
- Real-time user and post counts
- Growth tracking (weekly)
- Health monitoring

### 📝 Posts Management
- View all posts with search functionality
- Edit post titles and descriptions
- Delete posts with reason tracking
- Bulk operations support
- View associated media and metadata

### 👥 User Management
- View all users with search
- Suspend/unsuspend user accounts
- View user details and activity
- Track suspension reasons and dates
- User verification status

### 📈 Analytics
- System overview with key metrics
- Growth tracking (7-day periods)
- User engagement statistics
- Platform health monitoring

### 🏢 Business Services Management
- Review business service applications
- Update application status (pending/review/approved/rejected)
- Add admin notes to applications
- Track review history

### 💬 Chat Moderation
- Monitor global chat messages
- Delete inappropriate messages
- Track moderation actions
- User activity oversight

### 📋 Audit Trail
- All admin actions are logged
- Detailed action tracking with timestamps
- Reason tracking for destructive actions
- Admin accountability

## Setup Instructions

### 1. Database Setup
Run the provided SQL script in your Supabase SQL editor:

```sql
-- Run admin_setup.sql
```

This creates:
- Admin audit logs table
- Suspension columns in users table
- Proper RLS policies
- Required indexes

### 2. Admin Email Configuration
Update the admin email list in `/lib/features/admin/services/admin_auth_service.dart`:

```dart
static const List<String> _adminEmails = [
  'admin@foundervers.com',
  'raj@foundervers.com',
  'your-admin-email@domain.com', // Add your admin emails here
];
```

### 3. Access the Admin Panel
1. Log in with an admin email
2. Navigate to the Ecosystem Applications page
3. The admin panel will be visible at the bottom
4. Click "Open Admin Dashboard"

## Admin User Guide

### Dashboard Navigation
- **Dashboard Home**: Overview and analytics
- **Manage Posts**: Content moderation and editing
- **Manage Users**: User account management
- **Analytics**: Detailed system statistics
- **Business Services**: Service application reviews
- **Chat Moderation**: Global chat oversight

### Common Admin Tasks

#### Suspending a User
1. Go to "Manage Users"
2. Find the user (use search if needed)
3. Click the menu button (⋮) next to their name
4. Select "Suspend"
5. Enter a clear reason for suspension
6. Confirm the action

#### Deleting a Post
1. Go to "Manage Posts"
2. Find the post (use search if needed)
3. Click the menu button (⋮) on the post
4. Select "Delete"
5. Confirm the deletion
6. The action will be logged automatically

#### Reviewing Business Applications
1. Go to "Business Services"
2. Review application details
3. Click "Update Status"
4. Select appropriate status
5. Add admin notes if needed
6. Save changes

#### Moderating Chat Messages
1. Go to "Chat Moderation"
2. Review recent messages
3. Click the delete button (🗑️) for inappropriate content
4. Enter moderation reason
5. Confirm deletion

### Security Best Practices

1. **Admin Access**: Only add trusted team members to the admin email list
2. **Action Logging**: All admin actions are automatically logged
3. **Reason Required**: Always provide clear reasons for suspensions and deletions
4. **Regular Review**: Periodically review admin audit logs
5. **Secure Environment**: Ensure admin access is only from secure devices/networks

## Technical Details

### Architecture
- Modular design with separate services for each admin function
- Secure authentication using email-based role checking
- Comprehensive audit logging for all admin actions
- Responsive UI supporting both mobile and desktop admin work

### Database Schema
- `admin_audit_logs`: Tracks all admin actions
- `users.is_suspended`: User suspension status
- `users.suspension_reason`: Reason for suspension
- `users.suspended_at`: Suspension timestamp

### API Integration
- Uses existing Supabase client for all operations
- Leverages Row Level Security (RLS) for data protection
- Proper error handling and user feedback
- Efficient pagination for large datasets

## Troubleshooting

### Admin Access Issues
- Verify your email is in the admin whitelist
- Check that you're logged in with the correct account
- Ensure proper database permissions are set

### Performance Issues
- Admin queries are paginated (50-100 items per page)
- Use search functionality for large datasets
- Refresh data if information seems stale

### Error Handling
- All errors are displayed to the admin with clear messages
- Check the console for detailed error information
- Verify database connectivity and permissions

## Future Enhancements

Potential future additions:
- Advanced analytics with charts and graphs
- Bulk user operations (mass suspension/unsuspension)
- Content flagging and automated moderation
- Export functionality for audit reports
- Advanced search and filtering options
- Real-time notifications for admin actions

## Support

For admin system support:
- Check the troubleshooting section above
- Review the audit logs for action history
- Contact the development team for technical issues
- Document any bugs or feature requests

---

**Note**: This admin system provides powerful capabilities. Always use with caution and ensure proper backup procedures are in place before performing destructive actions.