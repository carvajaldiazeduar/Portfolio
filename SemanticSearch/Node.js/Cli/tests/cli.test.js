jest.mock("../../Web/Plain/src/storage/VectorFactory", () => ({
  createVectorStore: () => ({
    listCollections: jest.fn().mockReturnValue([]),
    search: jest.fn().mockReturnValue([]),
    deleteCollection: jest.fn(),
    close: jest.fn(),
  }),
}));

const { main } = require("../semantic_search");

test("main function exists", () => {
  expect(main).toBeDefined();
});