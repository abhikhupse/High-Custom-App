const apps = ['Dashboard', 'Leads', 'Social Links', 'Tracking Reports', 'User Management', 'Sequences'];
function denied(user, path, method) {
  if (!user || user.deletedAt || user.isActive === false) return 'Your account is inactive. Please contact admin.';
  if (user.accessRight === 'No Access') return 'Your account has no access.';
  const resource = path.split('?')[0].replace(/^\/api/, '');
  if (resource === '/user/edit-profile' && String(process.env.ADMIN_EMAILS || '').split(',').some(email => email.trim().toLowerCase() === String(user.email || '').toLowerCase())) return 'Administrators cannot edit their own profile.';
  if (/^\/user\/(profile|logout)$/.test(resource)) return null;
  if (user.accessRight === 'View Only' && !['GET', 'HEAD', 'OPTIONS'].includes(method)) return 'Your account has view-only access.';
  const app = /^\/admin\/users/.test(resource) ? 'User Management' : /^\/admin\/dashboard/.test(resource) ? 'Dashboard' : /^\/leads/.test(resource) ? 'Leads' : /^\/sequence/.test(resource) ? 'Sequences' : /^\/email-tracking/.test(resource) ? 'Tracking Reports' : /^\/(social-links|business-card|business-types|business-link-settings)/.test(resource) ? 'Social Links' : null;
  if (app && Array.isArray(user.appRights) && !user.appRights.includes(app)) return 'You do not have access to ' + app + '.';
  return null;
}
module.exports = { apps, denied };
