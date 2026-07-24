export default function SupportPage() {
  return (
    <main className="min-h-screen bg-background p-6 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Support</h1>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Contact Us</h2>
        <p className="mb-2">We are here to help. Reach out to us through any of the following channels:</p>
        <ul className="list-disc pl-6 mt-2 space-y-1">
          <li>Email: <a href="mailto:support@nomnom.lk" className="text-primary underline">support@nomnom.lk</a></li>
          <li>Response time: within 48 hours</li>
        </ul>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">Frequently Asked Questions</h2>

        <div className="space-y-4 mt-2">
          <div>
            <h3 className="font-medium">How do I find offers near me?</h3>
            <p className="text-muted-foreground text-sm">Browse the home screen or use the search feature to find offers by restaurant, cuisine, or discount type.</p>
          </div>

          <div>
            <h3 className="font-medium">How do I save my favorite offers?</h3>
            <p className="text-muted-foreground text-sm">Tap the heart icon on any offer to add it to your favorites. Access them anytime from the Favorites tab.</p>
          </div>

          <div>
            <h3 className="font-medium">How do I manage notifications?</h3>
            <p className="text-muted-foreground text-sm">Go to Settings &gt; Notifications in the app to manage your notification preferences.</p>
          </div>

          <div>
            <h3 className="font-medium">How do I delete my account?</h3>
            <p className="text-muted-foreground text-sm">
              Go to your Profile &gt; Delete Account in the app. Your account will be scheduled for deletion after a 30-day recovery period. Or visit our{' '}
              <a href="/delete-account" className="text-primary underline">account deletion page</a>.
            </p>
          </div>
        </div>
      </section>
    </main>
  )
}
