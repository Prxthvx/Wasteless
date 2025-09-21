@echo off
echo Committing authentication fixes...
git add .
git commit -m "Fix authentication flow issues

- Fix signup redirect to go to root instead of welcome screen
- Fix logout redirect to go to root instead of welcome screen  
- Fix asset loading errors by replacing logo with icon
- Fix layout constraint errors in welcome screen
- Ensure AuthWrapper properly handles authentication state

These fixes resolve:
- Users getting stuck on welcome screen after signup
- Users not being able to login after logout
- Blank screen issues due to asset loading errors
- Layout constraint errors causing app crashes"
echo.
echo Pushing to GitHub...
git push origin main
echo.
echo Done! Authentication fixes have been pushed to GitHub.
pause
