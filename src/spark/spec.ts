import { Spec } from "./shared";
import { deep_merge } from "./utils";

const DEFAULT_SPEC: Spec = {
  [1]: "",
  from: "",
  start: false,
  disable: false,
  priority: 0,
  after: [],
  __state: "NONE",
  __path: "",
};

export function new_spec(this: void, spec: DeepParitial<Spec>): Spec {
  return deep_merge(
    "keep",
    { __state: "NONE", __path: "" },
    spec,
    DEFAULT_SPEC
  );
}

export function validate(
  this: void,
  orig: DeepParitial<Spec>
): LuaMultiReturn<[Spec, undefined] | [undefined, string]> {
  const spec2 = new_spec(orig);
  const name = spec2[1];
  if (name == "") {
    return $multi(
      undefined,
      string.format("plugin name must be specified for '%s'", vim.inspect(orig))
    );
  } else if (string.sub(name, 1, 1) == "$") {
    spec2.__state = "POST_LOAD";
  } else {
    if (spec2.from == "") {
      return $multi(undefined, string.format("'from' is missed in '%s'", name));
    } else {
      spec2.from = "https://github.com/" + spec2.from;
    }
  }
  if (spec2.start && spec2.disable) {
    return $multi(
      undefined,
      string.format("start plugin '%s' cannot be disabled", name)
    );
  }
  return $multi(spec2, undefined);
}
