export default function DeleteAccountPage() {
  return (
    <main className="min-h-screen bg-background p-6 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Delete Your Account</h1>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">How to Delete Your NomNom LK Account</h2>
        <p className="mb-2">There are two ways to delete your account:</p>

        <div className="space-y-4 mt-2">
          <div className="border rounded-lg p-4">
            <h3 className="font-medium mb-1">Option 1: Delete from the App</h3>
            <ol className="list-decimal pl-6 text-sm text-muted-foreground space-y-1">
              <li>Open the NomNom LK app</li>
              <li>Go to your Profile tab</li>
              <li>Scroll down and tap &quot;Delete Account&quot;</li>
              <li>Confirm your choice in the dialog</li>
            </ol>
          </div>

          <div className="border rounded-lg p-4">
            <h3 className="font-medium mb-1">Option 2: Request by Email</h3>
            <p className="text-sm text-muted-foreground">
              Send an email to{' '}
              <a href="mailto:support@nomnom.lk" className="text-primary underline">support@nomnom.lk</a>
              {' '}with the subject &quot;Account Deletion Request&quot; and include the email address associated with your account.
              We will process your request within 48 hours.
            </p>
          </div>
        </div>
      </section>

      <section className="mb-6 p-4 border border-orange-200 dark:border-orange-800 rounded-lg bg-orange-50 dark:bg-orange-950/30">
        <h2 className="text-lg font-semibold mb-2">Important Information</h2>
        <ul className="list-disc pl-6 text-sm space-y-1">
          <li>Account deletion has a <strong>30-day recovery period</strong></li>
          <li>You can cancel the deletion request at any time during these 30 days</li>
          <li>After 30 days, your data will be <strong>permanently deleted</strong></li>
          <li>Deleted data cannot be recovered after the 30-day window</li>
        </ul>
      </section>

      <section className="mb-6">
        <h2 className="text-lg font-semibold mb-2">What Gets Deleted</h2>
        <ul className="list-disc pl-6 text-sm text-muted-foreground space-y-1">
          <li>Your account and profile information</li>
          <li>Your favorites and notification preferences</li>
          <li>Your device token for push notifications</li>
          <li>Your activity history (anonymized for analytics)</li>
        </ul>
      </section>
    </main>
  )
}
