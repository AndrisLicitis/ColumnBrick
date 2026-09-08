//
//  ColumnBrickApp.swift
//  ColumnBrick
//
//  Created by Andris Licitis on 04/09/2026.
//

import SwiftUI

@main
struct ColumnBrickApp: App {

  var body: some Scene {

    WindowGroup {
      ContentView()
        .frame(
          width: 460,
          height: 680
        )
    }
    .windowResizability(.contentSize)

    Settings {
      SettingsView()
    }
  }
}

// MARK: - Settings

struct SettingsView: View {

  @AppStorage("difficulty")
  private var difficulty = "Hard"

  var body: some View {

    Form {

      Picker(
        "Difficulty",
        selection: $difficulty
      ) {

        Text("Easy")
          .tag("Easy")

        Text("Medium")
          .tag("Medium")

        Text("Hard")
          .tag("Hard")
      }
    }
    .padding(20)
    .frame(
      width: 300
    )
  }
}
