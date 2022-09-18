export declare type LogLevel = vim.log.levels;
export declare const LogLevel: typeof vim.log.levels;
export declare type SpecState = "NONE" | "MOVE" | "CLONE" | "REMOVE" | "LOAD" | "LOADED";
export interface Spec {
    [1]: string;
    from: string;
    start: boolean;
    disable: boolean;
    priority: number;
    after: string[];
    run: Lua.MkFn<() => void> | string[];
    __state: SpecState;
    __path: string;
}
export declare const DEFAULT_SPEC: Spec;
export interface Config {
    [1]: Lua.MkFn<(use: Lua.MkFn<(spec: DeepParitial<Spec>) => void>) => void>;
    root: string;
    log: {
        level: LogLevel;
    };
    after_load: Lua.MkFn<(spec: Spec) => void>;
}
export declare const CONFIG: Config;
export declare const PLUGINS: Spec[];