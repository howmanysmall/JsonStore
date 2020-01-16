type LuaTable = Map<string, any>;
type LuaArray = Set<any>;

interface JsonStore {
	readonly _token: string;

	/**
	 * Returns the formatted endpoint url.
	 * @returns {string} The endpoint url.
	*/
	getUrl(): string;

	/**
	 * Returns the current token for the store.
	 * @param {boolean} fullUrl Whether or not the JsonStore url will be included.
	 * @returns {string} The token of the current store.
	 */
	getToken(fullUrl: boolean): string;

	/**
	 * Verifies that the web server is alive.
	 * @returns {boolean} True iff the web request succeeded.
	 */
	ping(): boolean;

	/**
	 * Send a `GET` request to your endpoint asynchronously.
	 * @param {string} path The path to perform GET request to.
	 * @returns {Promise} A promise that can be used for handling the code.
	 */
	getAsync(path: string): Promise<LuaTable | LuaArray | string>;

	/**
	 * Send a `GET` request to your endpoint.
	 * @param {string} path The path to perform GET request to.
	 * @returns {LuaArray | LuaArray | boolean} The data returned from database.
	 */
	get(path: string): LuaArray | LuaArray | boolean;

	/**
	 * Send a `DELETE` request to your endpoint asynchronously.
	 * @param {string} path The path to perform DELETE request to.
	 * @returns {Promise} A promise that can be used for handling the code.
	 */
	deleteAsync(path: string): Promise<boolean | string>;

	/**
	 * Send a `DELETE` request to your endpoint.
	 * @param {string} path The path to perform DELETE request to.
	 * @returns {boolean} True iff the request succeeded.
	 */
	delete(path: string): boolean;

	/**
	 * Send a `PUT` request to your endpoint asynchronously.
	 * @param {string} path The path to perform PUT request to.
	 * @param {LuaTable | LuaArray} content The data to PUT into the database.
	 * @returns {Promise} A promise that can be used for handling the code.
	 */
	putAsync(path: string, content: LuaTable | LuaArray): Promise<LuaTable | LuaArray | string>;

	/**
	 * Send a `PUT` request to your endpoint.
	 * @param {string} path The path to perform PUT request to.
	 * @param {LuaTable | LuaArray} content The data to PUT into the database.
	 * @returns {LuaTable | LuaArray | boolean} The content put into the database.
	 */
	put(path: string, content: LuaTable | LuaArray): LuaTable | LuaArray | boolean;

	/**
	 * Send a `POST` request to your endpoint asynchronously.
	 * @param {string} path The path to perform POST request to.
	 * @param {LuaTable | LuaArray} content The data to POST into the database.
	 * @returns {Promise} A promise that can be used for handling the code.
	 */
	postAsync(path: string, content: LuaTable | LuaArray): Promise<LuaTable | LuaArray | string>;

	/**
	 * Send a `POST` request to your endpoint.
	 * @param {string} path The path to perform POST request to.
	 * @param {LuaTable | LuaArray} content The data to POST into the database.
	 * @returns {LuaTable | LuaArray | boolean} The content POST'D into the database.
	 */
	post(path: string, content: LuaTable | LuaArray): LuaTable | LuaArray | boolean;

	/**
	 * This function is similar to DataStore2's `GetTable`, where it will set the data to the default if it doesn't exist asynchronously.
	 * @param {string} path The path to use.
	 * @param {LuaTable | LuaArray} defaultData The data to set as the default in the database.
	 * @returns {Promise} A promise that can be used for handling the code.
	 */
	getDefaultAsync(path: string, defaultData: LuaTable | LuaArray): Promise<LuaTable | LuaArray | string>;

	/**
	 * This function is similar to DataStore2's `GetTable`, where it will set the data to the default if it doesn't exist.
	 * @param {string} path The path to use.
	 * @param {LuaTable | LuaArray} defaultData The data to set as the default in the database.
	 * @returns {LuaTable | LuaArray | boolean} The data stored in the database.
	 */
	getDefault(path: string, defaultData: LuaTable | LuaArray): LuaTable | LuaArray | boolean;

	/**
	 * Destroys the JsonStore so it can't be used anymore.
	 * @returns {void}
	 */
	destroy(): void;
}

declare const JsonStore: new (token?: string) => JsonStore;
export = JsonStore;