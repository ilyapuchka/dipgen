//
//  Errors.swift
//  Commandant
//
//  Created by Justin Spahr-Summers on 2014-10-24.
//  Copyright (c) 2014 Carthage. All rights reserved.
//

import Foundation
import Result

#if swift(>=3)
	public typealias ClientErrorType = ErrorProtocol
#else
	public typealias ClientErrorType = ErrorType
#endif

/// Possible errors that can originate from Commandant.
///
/// `ClientError` should be the type of error (if any) that can occur when
/// running commands.
public enum CommandantError<ClientError>: ClientErrorType {
	/// An option was used incorrectly.
	case UsageError(description: String)

	/// An error occurred while running a command.
	case CommandError(ClientError)
}

extension CommandantError: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .UsageError(description):
			return description

		case let .CommandError(error):
			return String(error)
		}
	}
}

/// Constructs an `InvalidArgument` error that indicates a missing value for
/// the argument by the given name.
internal func missingArgumentError<ClientError>(argumentName: String) -> CommandantError<ClientError> {
	let description = "Missing argument for \(argumentName)"
	return .UsageError(description: description)
}

/// Constructs an error by combining the example of key (and value, if applicable)
/// with the usage description.
internal func informativeUsageError<ClientError>(keyValueExample: String, usage: String) -> CommandantError<ClientError> {
	let lines = usage.componentsSeparatedByCharacters(in: NSCharacterSet.newline())

	return .UsageError(description: lines.reduce(keyValueExample) { previous, value in
		return previous + "\n\t" + value
	})
}

/// Combines the text of the two errors, if they're both `UsageError`s.
/// Otherwise, uses whichever one is not (biased toward the left).
internal func combineUsageErrors<ClientError>(lhs: CommandantError<ClientError>, _ rhs: CommandantError<ClientError>) -> CommandantError<ClientError> {
	switch (lhs, rhs) {
	case let (.UsageError(left), .UsageError(right)):
		let combinedDescription = "\(left)\n\n\(right)"
		return .UsageError(description: combinedDescription)

	case (.UsageError, _):
		return rhs

	case (_, .UsageError), (_, _):
		return lhs
	}
}

/// Constructs an error that indicates unrecognized arguments remains.
internal func unrecognizedArgumentsError<ClientError>(options: [String]) -> CommandantError<ClientError> {
	return .UsageError(description: "Unrecognized arguments: " + options.joined(separator: ", "))
}

// MARK: Argument

/// Constructs an error that describes how to use the argument, with the given
/// example of value usage if applicable.
internal func informativeUsageError<T, ClientError>(valueExample: String, argument: Argument<T>) -> CommandantError<ClientError> {
	if argument.defaultValue != nil {
		return informativeUsageError("[\(valueExample)]", usage: argument.usage)
	} else {
		return informativeUsageError(valueExample, usage: argument.usage)
	}
}

/// Constructs an error that describes how to use the argument.
internal func informativeUsageError<T: ArgumentType, ClientError>(argument: Argument<T>) -> CommandantError<ClientError> {
	var example = ""

	var valueExample = ""
	if let defaultValue = argument.defaultValue {
		valueExample = "\(defaultValue)"
	}

	if valueExample.isEmpty {
		example += "(\(T.name))"
	} else {
		example += valueExample
	}

	return informativeUsageError(example, argument: argument)
}

/// Constructs an error that describes how to use the argument list.
internal func informativeUsageError<T: ArgumentType, ClientError>(argument: Argument<[T]>) -> CommandantError<ClientError> {
	var example = ""

	var valueExample = ""
	if let defaultValue = argument.defaultValue {
		valueExample = "\(defaultValue)"
	}

	if valueExample.isEmpty {
		example += "(\(T.name))"
	} else {
		example += valueExample
	}

	return informativeUsageError(example, argument: argument)
}

// MARK: Option

/// Constructs an error that describes how to use the option, with the given
/// example of key (and value, if applicable) usage.
internal func informativeUsageError<T, ClientError>(keyValueExample: String, option: Option<T>) -> CommandantError<ClientError> {
	return informativeUsageError("[\(keyValueExample)]", usage: option.usage)
}

/// Constructs an error that describes how to use the option.
internal func informativeUsageError<T: ArgumentType, ClientError>(option: Option<T>) -> CommandantError<ClientError> {
	return informativeUsageError("--\(option.key) \(option.defaultValue)", option: option)
}

/// Constructs an error that describes how to use the option.
internal func informativeUsageError<T: ArgumentType, ClientError>(option: Option<T?>) -> CommandantError<ClientError> {
	return informativeUsageError("--\(option.key) (\(T.name))", option: option)
}

/// Constructs an error that describes how to use the given boolean option.
internal func informativeUsageError<ClientError>(option: Option<Bool>) -> CommandantError<ClientError> {
	let key = option.key
	return informativeUsageError((option.defaultValue ? "--no-\(key)" : "--\(key)"), option: option)
}
