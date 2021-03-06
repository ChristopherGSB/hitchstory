from hitchstory import exceptions
from strictyaml import Any, Optional
from hitchstory import utils
from functools import partial
import inspect


class StepMethod(object):
    def __init__(self, method):
        self._method = method
        if self.argspec.varargs is not None:
            raise exceptions.CannotUseVarargs((
                "Method '{}' uses varargs (e.g. *args), "
                "only keyword args (e.g. **kwargs) are valid".format(
                    self._method
                )
            ))
        if self._keywords and len(self._args) > 1:
            raise exceptions.CannotMixKeywordArgs((
                "Method '{}' mixes keyword (e.g. *kwargs), "
                "and regular args (e.g. arg1, arg2, arg3). "
                "Mixing is not allowed".format(
                    self._method
                )
            ))

    @property
    def argspec(self):
        return inspect.getargspec(self._method)

    @property
    def _defaults(self):
        return self.argspec.defaults if self.argspec.defaults is not None else []

    @property
    def _args(self):
        return self.argspec.args if self.argspec.args is not None else []

    @property
    def _specified_validators(self):
        return self._method._validators if hasattr(self._method, "_validators") else {}

    @property
    def _keywords(self):
        return self.argspec.keywords is not None

    def arg_validator(self, name):
        return utils.YAML_Param | self._specified_validators.get(name, Any())

    @property
    def optional_args(self):
        return self.argspec.args[-len(self._defaults) :]

    @property
    def required_args(self):
        return self.argspec.args[: len(self._args) - len(self._defaults)][1:]

    @property
    def single_argument_allowed(self):
        return (
            len(self.required_args) == 0
            and len(self.optional_args) > 1
            or len(self.required_args) == 1
        )

    @property
    def no_arguments_allowed(self):
        return len(self.required_args) == 0 and len(self.optional_args) == 1

    @property
    def single_argument_name(self):
        return self.argspec.args[1]

    @property
    def mapping_validators(self):
        validators = {}
        for arg in self.optional_args:
            validators[Optional(arg)] = self.arg_validator(arg)
        for arg in self.required_args:
            validators[arg] = self.arg_validator(arg)
        return validators

    def revalidate(self, arguments):
        if arguments.single_argument:
            if self.single_argument_allowed:
                arguments.validate_single_argument(
                    self.arg_validator(self.single_argument_name)
                )
            elif self.no_arguments_allowed:
                raise exceptions.StepShouldNotHaveArguments(
                    (
                        "Step method {0} cannot have one or more arguments, "
                        "but it has at least one (maybe because of a : the end of the line)."
                    ).format(self._method)
                )
            else:
                raise exceptions.StepMethodNeedsMoreThanOneArgument(
                    "Step method {0} requires {1} arguments, got one.".format(
                        self._method, len(self.required_args)
                    )
                )
        else:
            if self._keywords:
                arguments.validate_kwargs(self.arg_validator(self._keywords))
            else:
                arguments.validate_args(self.mapping_validators)

    def method(self, arguments):
        if arguments.is_none:
            return self._method
        elif arguments.single_argument:
            return partial(self._method, **{self.single_argument_name: arguments.data})
        else:
            return partial(self._method, **arguments.data)
