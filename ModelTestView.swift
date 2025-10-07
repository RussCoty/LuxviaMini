import SwiftUI
import CoreML

struct ModelTestView: View {
    @State private var input: String = "She loved gardening and baking."
    @State private var predictedLabel: String = ""
    @State private var confidence: Double? = nil
    @State private var topProbs: [(String, Double)] = []
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("LuxviaMini • Model Test")
                .font(.title).bold()

            TextField("Enter text to classify…", text: $input)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button("Run Model", action: runPrediction)
                .buttonStyle(.borderedProminent)

            if !predictedLabel.isEmpty {
                VStack(spacing: 6) {
                    Text("Predicted Label:")
                        .font(.headline)
                    Text(predictedLabel)
                        .font(.title3)
                        .foregroundColor(.blue)

                    if let conf = confidence {
                        Text(String(format: "Confidence: %.1f%%", conf * 100))
                            .foregroundColor(.secondary)
                    }

                    if !topProbs.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Top predictions:")
                                .font(.subheadline).bold()
                            ForEach(topProbs.indices, id: \.self) { i in
                                let item = topProbs[i]
                                Text(String(format: "• %@ — %.1f%%", item.0, item.1 * 100))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
            }

            if !errorMessage.isEmpty {
                Text("⚠️ \(errorMessage)")
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Prediction
    func runPrediction() {
        do {
            let model = try LuxSlotClassifier(configuration: MLModelConfiguration())
            let result = try model.prediction(text: input)

            predictedLabel = result.label

            let probKeys = ["labelProbability", "labelProbabilities", "classLabelProbs"]
            var bestConf: Double? = nil
            var probsDict: [String: Double] = [:]

            for key in probKeys {
                if let fv = result.featureValue(for: key) {
                    var tmp: [String: Double] = [:]
                    for (k, v) in fv.dictionaryValue {
                        if let kStr = k as? String {
                            tmp[kStr] = v.doubleValue
                        }
                    }
                    if !tmp.isEmpty {
                        probsDict = tmp
                        break
                    }
                }
            }

            if !probsDict.isEmpty {
                bestConf = probsDict[predictedLabel]
                topProbs = Array(probsDict.sorted { $0.value > $1.value }.prefix(3))
            } else {
                topProbs = []
            }

            confidence = bestConf
            errorMessage = ""

        } catch {
            predictedLabel = ""
            confidence = nil
            topProbs = []
            errorMessage = "Error running model: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ModelTestView()
}
