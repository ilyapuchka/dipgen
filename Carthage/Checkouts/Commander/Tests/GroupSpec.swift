import Spectre
import Commander


extension ExpectationType where ValueType == CommandType {
  func run(arguments: [String]) throws -> Expectation<Void> {
    if let command = try expression() {
      return expect {
        try command.run(arguments)
      }
    }

    throw failure("command was nil")
  }
}


func testGroup() {
  describe("Group") {
    $0.it("dispatches subcommands when ran") {
      var didRunHelpCommand = false

      let group = Group()
      group.addCommand("help", command {
        didRunHelpCommand = true
      })

      try expect(didRunHelpCommand).to.beFalse()
      try expect(group).run(["unknown"]).toThrow()
      try expect(didRunHelpCommand).to.beFalse()

      try group.run(["help"])
      try expect(didRunHelpCommand).to.beTrue()
    }

    $0.it("catches and reraises errors with command name") {
      let group = Group {
        $0.group("subgroup") {
          $0.command("command") {}
        }
      }

      try expect(group).run(["subgroup", "yo"]).toThrow(GroupError.UnknownCommand("subgroup yo"))
    }

    $0.it("throws an error when the command name is missing") {
      let group = Group()

      do {
        try group.run([])
        throw failure("Didn't raise an error")
      } catch GroupError.NoCommand(let path, let raisedGroup) {
        try expect(path).to.beNil()
        if raisedGroup !== group {
          throw failure("\(raisedGroup) is not \(group)")
        }
      } catch {
        throw error
      }
    }

    $0.it("reraises missing sub-group command name including command name") {
      let subgroup = Group()
      let group = Group { $0.addCommand("group", subgroup) }

      try expect(group).run(["group"]).toThrow(GroupError.NoCommand("group", subgroup))
    }

    $0.it("reraises missing sub-sub-group command name including group and command name") {
      let subsubgroup = Group()
      let subgroup = Group { $0.addCommand("g2", subsubgroup) }
      let group = Group { $0.addCommand("g1", subgroup) }

      try expect(group).run(["g1", "g2"]).toThrow(GroupError.NoCommand("g1 g2", subsubgroup))
    }

    $0.describe("extensions") {
      $0.it("has a convinience initialiser calling a builder closure") {
        var didRunHelpCommand = false

        let group = Group {
          $0.addCommand("help", command {
            didRunHelpCommand = true
          })
        }

        try expect(group).run(["unknown"]).toThrow()
        try expect(didRunHelpCommand).to.beFalse()

        try group.run(["help"])
        try expect(didRunHelpCommand).to.beTrue()
      }

      $0.it("has a convinience sub-group function") {
        var didRun = false

        try Group {
          $0.group("group") {
            $0.command("test") {
              didRun = true
            }
          }
        }.run(["group", "test"])

        try expect(didRun).to.beTrue()
      }

      $0.it("has a convinience sub-command function") {
        var didRun = false

        try Group {
          $0.command("test") {
            didRun = true
          }
        }.run(["test"])

        try expect(didRun).to.beTrue()
      }

      $0.it("has a convinience sub-command function with arguments") {
        var givenName:String? = nil

        try Group {
          $0.command("test") { (name:String) in
            givenName = name
          }
        }.run(["test", "kyle"])

        try expect(givenName) == "kyle"
      }
    }
  }

  describe("Group") {
    let group = Group {
      $0.command("create") {}
      $0.command("lint") {}
    }

    $0.describe("error description") {
      $0.it("unknown command") {
        let error = GroupError.UnknownCommand("pod spec create")
        try expect(error.description) == "Unknown command: `pod spec create`"
      }

      $0.it("no command") {
        let error = GroupError.NoCommand("pod lib", group)
        try expect(error.description) == "Usage: pod lib COMMAND\n\nCommands: create, lint"
      }

      $0.it("no command without path") {
        let error = GroupError.NoCommand(nil, group)
        try expect(error.description) == "Commands: create, lint"
      }
    }
  }
}
