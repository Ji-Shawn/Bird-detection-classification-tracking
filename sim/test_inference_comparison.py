"""Check the comparator with synthetic mutations; not inference/board evidence."""
import copy, json, unittest
from compare_inference import compare,SAMPLES

class ComparisonTests(unittest.TestCase):
    def setUp(self):self.ref=json.loads((SAMPLES/'expected.json').read_text())
    def test_reordered_detections(self):
        actual=copy.deepcopy(self.ref);actual['3']['detections'].reverse()
        self.assertEqual(compare(self.ref,actual)['status'],'pass_numeric')
    def test_same_top1_is_insufficient(self):
        actual=copy.deepcopy(self.ref);actual['1']['logits'][0]+=1
        self.assertEqual(compare(self.ref,actual)['status'],'fail_numeric')
    def test_missing_detection(self):
        actual=copy.deepcopy(self.ref);actual['3']['detections'].pop()
        self.assertEqual(compare(self.ref,actual)['status'],'fail_numeric')
    def test_extra_model(self):
        actual=copy.deepcopy(self.ref);actual['4']={}
        with self.assertRaises(ValueError):compare(self.ref,actual)
    def test_nan_score(self):
        actual=copy.deepcopy(self.ref);actual['3']['detections'][0]['score']=float('nan')
        with self.assertRaises(ValueError):compare(self.ref,actual)
    def test_probability_rejected(self):
        actual=copy.deepcopy(self.ref);actual['2']['logits'][0]=.5
        with self.assertRaises(ValueError):compare(self.ref,actual)
    def test_duplicate_anchor_rejected(self):
        actual=copy.deepcopy(self.ref);actual['3']['detections'][1]['anchor']=actual['3']['detections'][0]['anchor']
        with self.assertRaises(ValueError):compare(self.ref,actual)
    def test_boundary_tolerance(self):
        actual=copy.deepcopy(self.ref);actual['3']['detections'][0]['box'][0]+=.125
        self.assertEqual(compare(self.ref,actual,box_tol=.125)['status'],'pass_numeric')
        self.assertEqual(compare(self.ref,actual,box_tol=.124)['status'],'fail_numeric')

if __name__=='__main__':unittest.main()
