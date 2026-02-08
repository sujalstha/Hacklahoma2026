import SwiftUI
import Supabase

@main
struct whatsForDinnerApp: App {
    let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://cwsazjkvaxdhyksbonpx.supabase.co")!,
        supabaseKey: "sb_publishable_XE_Wywod1X0rbO3DdkUjsA_KHJi4_A5"
    )

    var body: some Scene {
        WindowGroup {
            LoginView(supabase: supabase)
        }
    }
}

